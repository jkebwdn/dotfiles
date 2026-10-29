#!/usr/bin/env python3
"""Read-only ANSI fetch composition. No theme writes or input consumption."""
import argparse
import json
import math
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import select
import termios
import sys
import time
import unicodedata

sys.dont_write_bytecode = True
WIDTH, HEIGHT = 35, 15
FONT = {
    'N': ('##   ##','###  ##','## # ##','##  ###','##   ##'),
    'E': ('#######','##     ','###### ','##     ','#######'),
    'R': ('###### ','##   ##','###### ','##  ## ','##   ##'),
    'V': ('##   ##','##   ##','##   ##',' ## ## ','  ###  '),
}
ESC = '\x1b['
RESET = ESC+'0m'
TOKEN = re.compile(r'\x1b\[[0-?]*[ -/]*[@-~]|\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)|.', re.S)


def cell_width(c):
    return 0 if unicodedata.combining(c) else 2 if unicodedata.east_asian_width(c) in ('W','F') else 1


def safe_line(text, limit=1000, color=True):
    """Keep SGR only; resolve Fastfetch's absolute key columns before composing."""
    result, column = [], 0
    for match in TOKEN.finditer(text):
        token = match[0]
        if token.startswith('\x1b'):
            if re.fullmatch(r'\x1b\[[0-9;:]*m',token):
                if color: result.append(token)
            elif re.fullmatch(r'\x1b\[\d*G',token):
                count = min(limit-column,max(0,int(token[2:-1] or '1')-1-column))
                result.append(' '*count);column += count
            continue
        if token == '\t': token = ' '*(8-column%8)
        if any(ord(c)<32 or 127<=ord(c)<160 for c in token): continue
        size = sum(cell_width(c) for c in token)
        if column+size>limit: break
        result.append(token);column += size
    return ''.join(result)+(RESET if color else ''), column


def palette():
    # Reuse the existing canonical resolver; no independent colour table or writes.
    from theme_orchestrator.palette import REGISTRY, resolve
    default = json.loads(REGISTRY.read_text())['default']
    selected = default
    try:
        selected = json.loads((Path(os.environ.get('XDG_CONFIG_HOME',Path.home()/'.config'))/'quickshell/magi/settings.json').read_text())['appearance']['theme']
    except (OSError,ValueError,KeyError,TypeError): pass
    try: canonical = resolve(selected)
    except (ValueError,TypeError): canonical = resolve(default)
    data = Path(os.environ.get('XDG_DATA_HOME',Path.home()/'.local/share'))
    try:
        published = json.loads((data/'magi/theme-orchestrator/ghostty/current/palette.json').read_text())
        if published == canonical: return published['roles']
    except (OSError,ValueError): pass
    return canonical['roles']


def project(latitude, longitude, angle):
    x = math.cos(latitude)*math.sin(longitude+angle)
    y = math.sin(latitude)
    z = math.cos(latitude)*math.cos(longitude+angle)
    tilt = .17
    return x*math.cos(tilt)-y*math.sin(tilt), x*math.sin(tilt)+y*math.cos(tilt), z


def geometry(angle):
    """Fixed-size subcell raster, with a front/back depth buffer."""
    pixels = {}
    def curve(points):
        previous = None
        for lat,lon in points:
            x,y,z = project(lat,lon,angle)
            point = ((x*.40+.5)*(WIDTH*2-1),(.5-y*.47)*(HEIGHT*4-1),z)
            if previous is not None:
                steps = max(1,math.ceil(max(abs(point[0]-previous[0]),abs(point[1]-previous[1]))))
                for step in range(steps+1):
                    f=step/steps
                    px,py=(round(previous[i]+f*(point[i]-previous[i])) for i in (0,1))
                    depth=previous[2]+f*(point[2]-previous[2])
                    if 0<=px<WIDTH*2 and 0<=py<HEIGHT*4:
                        pixels[px,py]=max(depth,pixels.get((px,py),-2))
            previous=point
    for i in range(12):
        curve([(-math.pi/2+j*math.pi/96,i*math.tau/12) for j in range(97)])
    for lat in (-60,-40,-20,0,20,40,60):
        curve([(math.radians(lat),j*math.tau/192) for j in range(193)])
    return pixels


def frame(angle, ascii_only=False):
    pixels=geometry(angle);cells={}
    dots=((1,8),(2,16),(4,32),(64,128))
    for (x,y),depth in pixels.items():
        cell=(x//2,y//4);bits,z=cells.get(cell,(0,-2))
        cells[cell]=(bits|dots[y%4][x%2],max(z,depth))
    result=[]
    for y in range(HEIGHT):
        row=[]
        for x in range(WIDTH):
            bits,z=cells.get((x,y),(0,-2))
            char=('+' if z>=0 else '.') if ascii_only and bits else chr(0x2800+bits) if bits else ' '
            row.append((char,'teal' if z>=0 else 'muted'))
        result.append(row)
    word=[' '.join(FONT[c][y] for c in 'NERV') for y in range(5)]
    start=(WIDTH-len(word[0]))//2
    for y in range(4,11):
        for x in range(start-1,start+len(word[0])+1):result[y][x]=(' ','text')
    for y,line in enumerate(word,5):
        for x,c in enumerate(line,start):result[y][x]=(('NERV'[(x-start)//8] if ascii_only else '█') if c=='#' else ' ','accent')
    subtitle='MAGI SYSTEM'
    for x,c in enumerate(' '+subtitle+' ',(WIDTH-len(subtitle)-2)//2):result[11][x]=(c,'text')
    return result


def ink(role, roles, mode):
    if mode=='none':return ''
    if mode=='ansi':return ESC+{'accent':'95','teal':'96','muted':'90','text':'97'}[role]+'m'
    color=roles[role]
    return ESC+'38;2;'+';'.join(str(int(color[i:i+2],16)) for i in (1,3,5))+'m'


def render(angle, roles, mode='truecolor', ascii_only=False):
    lines=[]
    for row in frame(angle,ascii_only):
        last=None;line=''
        for char,role in row:
            if char!=' ' and role!=last:line+=ink(role,roles,mode);last=role
            line+=char
        lines.append(line+(RESET if mode!='none' else ''))
    return lines


def fetch(color):
    if not shutil.which('fastfetch'):return ['Fastfetch is not installed.']
    try:
        p=subprocess.run(['fastfetch','--logo','none','--pipe','false' if color else 'true'],
                         text=True,capture_output=True,timeout=5,check=True,
                         env=dict(os.environ, FFTS_IGNORE_PARENT='1'))
        lines=[safe_line(line,color=color)[0] for line in p.stdout.splitlines()][:200]
        while lines and not safe_line(lines[-1],color=False)[0].strip():lines.pop()
        return lines
    except (OSError,subprocess.SubprocessError):return ['Fastfetch unavailable; try fastfetch directly.']


def terminal_size():
    # Shell-exported COLUMNS/LINES may describe the pre-map window. The PTY wins.
    try:
        size=os.get_terminal_size(sys.stdout.fileno())
        if size.columns>0 and size.lines>0:return size
    except (OSError,ValueError):pass
    return shutil.get_terminal_size((80,24))


def layout(columns, rows, info):
    info_width=max((safe_line(line,color=False)[1] for line in info),default=0)
    return columns>=WIDTH+3+info_width+1 and rows>=max(HEIGHT,len(info))+2


def static_output(info, roles, mode, columns, rows, ascii_only=False, angle=.35):
    if not layout(columns,rows,info):
        return ['NERV / MAGI SYSTEM']+[safe_line(line,max(1,columns-1),mode!='none')[0] for line in info]
    logo=render(angle,roles,mode,ascii_only)
    height=max(HEIGHT,len(info))
    logo_top=(height-HEIGHT)//2;info_top=(height-len(info))//2
    return [(logo[y-logo_top] if logo_top<=y<logo_top+HEIGHT else ' '*WIDTH)+'   '
            +(info[y-info_top] if info_top<=y<info_top+len(info) else '') for y in range(height)]


def main(argv=None):
    parser=argparse.ArgumentParser(description='MAGI-themed rotating NERV wireframe beside Fastfetch. Safe foreground terminal animation.')
    group=parser.add_mutually_exclusive_group();group.add_argument('--static',action='store_true');group.add_argument('--loop',action='store_true');group.add_argument('--until-key',action='store_true',help='Animate until the first key; leave it queued for the shell')
    parser.add_argument('--no-color',action='store_true');parser.add_argument('--ascii',action='store_true')
    args=parser.parse_args(argv)
    tty=sys.stdout.isatty() and os.environ.get('TERM','dumb')!='dumb'
    mode='none' if args.no_color or 'NO_COLOR' in os.environ or not tty else 'truecolor' if os.environ.get('COLORTERM') in ('truecolor','24bit') or os.environ.get('TERM')=='xterm-ghostty' else 'ansi'
    unicode_ok='utf' in (sys.stdout.encoding or '').lower()
    ascii_only=args.ascii or not unicode_ok
    if not unicode_ok: sys.stdout.reconfigure(errors='replace')
    roles=palette();info=fetch(mode!='none');size=terminal_size()
    animate=tty and sys.stdin.isatty() and not args.static and layout(size.columns,size.lines,info)
    if not animate:
        print('\n'.join(static_output(info,roles,mode,size.columns,size.lines,ascii_only)))
        return 0
    stop=[False];resized=[False]
    def halt(signum, unused):stop[0]=True
    def resize(signum, unused):resized[0]=True
    handlers={s:signal.getsignal(s) for s in (signal.SIGINT,signal.SIGTERM,signal.SIGWINCH,signal.SIGTSTP,signal.SIGQUIT,signal.SIGHUP)}
    for s in handlers:signal.signal(s,resize if s==signal.SIGWINCH else halt)
    height=max(HEIGHT,len(info));logo_top=(height-HEIGHT)//2
    started=time.monotonic();angle=.35
    original_mode=termios.tcgetattr(sys.stdin.fileno())
    quiet_mode=original_mode.copy();quiet_mode[6]=original_mode[6].copy()
    quiet_mode[3] &= ~termios.ECHO
    if args.until_key:
        quiet_mode[3] &= ~termios.ICANON
        quiet_mode[6][termios.VMIN]=1;quiet_mode[6][termios.VTIME]=0
    # Reserve rows in normal scrollback. Every update starts/ends below the block;
    # only left-side cells are touched. No alternate screen or input reads; TCSANOW preserves queued keys.
    try:
        termios.tcsetattr(sys.stdin.fileno(),termios.TCSANOW,quiet_mode)
        sys.stdout.write(ESC+'?25l'+'\n'.join(static_output(info,roles,mode,size.columns,size.lines,ascii_only))+'\n');sys.stdout.flush()
        while not stop[0] and not resized[0] and (args.loop or args.until_key or time.monotonic()-started<2):
            if select.select([sys.stdin],[],[],1/20)[0]:break
            if stop[0]:break
            if resized[0] or terminal_size()!=size:break
            angle=.35+(time.monotonic()-started)*.9
            lines=render(angle,roles,mode,ascii_only)
            output=ESC+str(height-logo_top)+'A\r'
            for y,line in enumerate(lines):
                output+=line
                if y<HEIGHT-1:output+=ESC+'1B\r'
            output+=ESC+str(height-logo_top-HEIGHT+1)+'B\r'
            sys.stdout.write(output);sys.stdout.flush()
    finally:
        try:termios.tcsetattr(sys.stdin.fileno(),termios.TCSANOW,original_mode)
        except termios.error:pass  # Terminal may have disappeared on SIGHUP.
        for s,h in handlers.items():signal.signal(s,h)
        sys.stdout.write(RESET+ESC+'?25h\r');sys.stdout.flush()
    return 0


if __name__=='__main__':
    try:sys.exit(main())
    except BrokenPipeError:
        # Redirect a closed consumer without another failed stdout flush at exit.
        os.dup2(os.open(os.devnull,os.O_WRONLY),sys.stdout.fileno())
    except KeyboardInterrupt:sys.exit(130)
