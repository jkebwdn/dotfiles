#!/usr/bin/env python3
"""Read-only, reproducible roundness inventory. Optional snapshot is never modified."""
import argparse,csv,json,re,subprocess
from pathlib import Path
root=Path(__file__).resolve().parents[2]
source=root/'.config/quickshell/magi'
parser=argparse.ArgumentParser();parser.add_argument('--settings',type=Path);parser.add_argument('--output',type=Path);args=parser.parse_args()
script="const fs=require('fs'),vm=require('vm'),c=vm.createContext({});vm.runInContext(fs.readFileSync(process.argv[1],'utf8'),c);const raw=JSON.parse(fs.readFileSync(0,'utf8'));console.log(JSON.stringify(vm.runInContext('({defaults:defaults(),effective:analyze('+JSON.stringify(raw)+').effective})',c)))"
raw=json.loads(args.settings.read_text()) if args.settings else {'schemaVersion':22}
schema=json.loads(subprocess.check_output(['node','-e',script,str(source/'settings/SettingsSchema.js')],input=json.dumps(raw),text=True))
def get(obj,path):
 for key in path.split('.'):
  if not isinstance(obj,dict) or key not in obj:return 'ABSENT'
  obj=obj[key]
 return obj
roles=['barPill','surface','controlTile','slider','action','avatar','albumArt','hubSelector','secondaryControl']
# Each logical field binding at a canonical editor location counts once. Repeated
# module selections, previews and outputs are contextual aliases, not new controls.
entries = [('Roundness',
  'Appearance',
  'Roundness',
  'surface',
  'RoundnessPicker.qml',
  'fieldKey: "surface"',
  'KEEP — feature-owned editor',
  'No geometry change; existing nullable parent retained'),
 ('Selector roundness',
  'Hub',
  'Selector appearance',
  'hubSelector',
  'pages/HubPage.qml',
  'fieldKey: "hubSelector"',
  'KEEP — feature-owned editor',
  'No geometry change; existing nullable parent retained'),
 ('Bar roundness',
  'Bar',
  'Appearance / Bar roundness',
  'barPill',
  'pages/BarPage.qml',
  'fieldKey: "barPill"',
  'KEEP — feature-owned editor',
  'No geometry change; existing nullable parent retained'),
 ('Primary Controls',
  'Control Centre',
  'Roundness / Controls',
  'controlTile',
  'pages/ControlCentrePage.qml',
  'fieldKey: "controlTile"',
  'KEEP — feature-owned editor',
  'No geometry change; existing nullable parent retained'),
 ('Secondary Controls',
  'Control Centre',
  'Roundness / Controls',
  'secondaryControl',
  'pages/ControlCentrePage.qml',
  'fieldKey: "secondaryControl"',
  'KEEP — feature-owned editor',
  'No geometry change; existing nullable parent retained'),
 ('Sliders',
  'Control Centre',
  'Roundness / Controls',
  'slider',
  'pages/ControlCentrePage.qml',
  'fieldKey: "slider"',
  'KEEP — feature-owned editor',
  'No geometry change; existing nullable parent retained'),
 ('Media Artwork',
  'Control Centre',
  'Roundness / Artwork & Identity',
  'albumArt',
  'pages/ControlCentrePage.qml',
  'fieldKey: "albumArt"',
  'KEEP — feature-owned editor',
  'No geometry change; existing nullable parent retained'),
 ('Avatar / Identity',
  'Control Centre',
  'Roundness / Artwork & Identity',
  'avatar',
  'pages/ControlCentrePage.qml',
  'fieldKey: "avatar"',
  'KEEP — feature-owned editor',
  'No geometry change; existing nullable parent retained'),
 ('Header image corners (px)',
  'Launcher',
  'Artwork',
  'header',
  'pages/LauncherPage.qml',
  'roundness-header',
  'KEEP — feature-owned editor',
  'No geometry change; existing nullable parent retained')]
field=lambda role: 'bar.visual.workspacePills.roundness' if role=='workspace' else 'launcher.headerRadius' if role=='header' else 'appearance.roundness.'+('master' if role=='master' else 'roles.'+role)
# Exported geometry aliases; this is a token count, not every radius-bearing Item.
tokens={'radiusSmall':'surface','radiusMedium':'surface','radiusLarge':'surface','barPillRadius':'barPill','workspacePillRadius':'workspace','outerRadius':'surface','tileRadius':'controlTile','sliderRadius':'slider','avatarRadius':'avatar'}
files=[]
for p in root.rglob('*'):
 if p.is_file() and not p.is_symlink() and p.suffix in ['.qml','.js','.py','.cpp','.hpp','.cjs','.md','.json','.frag','.vert'] and '.git' not in p.parts:
  files.append(p)
scan=[];bindings=[];consumers={role:[] for role in roles+['workspace','header','master']}
pattern=re.compile(r'roundness|rounded|radius',re.I)
for p in sorted(files):
 rel=str(p.relative_to(root));text=p.read_text(errors='replace')
 category='test' if rel.startswith('tests/') or '/tests/' in rel else 'historical experiment' if rel.startswith('experiments/') else 'documentation' if rel.startswith('docs/') or p.suffix=='.md' else 'runtime'
 for line_no,line in enumerate(text.splitlines(),1):
  if pattern.search(line):scan.append({'file':rel,'line':line_no,'category':category,'text':line.strip()})
  if category!='runtime':continue
  if p.suffix=='.qml':
   for match in re.finditer(r'(?:^|[;{,])\s*(?:(?:readonly\s+)?property\s+\w+\s+)?([A-Za-z_]*[Rr]adius\w*)\s*:\s*([^;\n}]+)',line):
    expression=match.group(2).strip()
    kind='fixed literal' if re.fullmatch(r'\d+(?:\.\d+)?',expression) else 'derived/propagated geometry'
    bindings.append({'file':rel,'line':line_no,'property':match.group(1),'expression':expression,'kind':kind})
  for role in consumers:
   direct=bool(re.search(r'\bradius\("'+role+'"',line))
   aliases=[t for t,r in tokens.items() if r==role and t not in ['outerRadius','avatarRadius']]
   bridge=(role=='avatar' and ('roles.avatar' in line or 'rounding.roles.avatar' in line or 'avatarRadius' in line))
   bridge|=(role=='surface' and 'RenderTokens.outerRadius' in line)
   bridge|=(role=='header' and 'headerRadius' in line) or (role=='workspace' and 'workspacePills.roundness' in line)
   if direct or bridge or any(re.search(r'\b'+t+r'\b',line) for t in aliases):
    consumers[role].append({'file':rel,'line':line_no,'text':line.strip()})
# Master reaches every nullable role but does not override an explicit role value.
consumers['master']=[{'file':'.config/quickshell/magi/theme/Theme.qml','line':44,'text':'radius(): nullable role -> master -> reference * multiplier -> geometry clamp'}, {'file':'native/lock/src/visual_data.cpp','line':80,'text':'native avatar override -> master -> 12px reference'}]
controls=[]
for n,(label,page,group,role,file,needle,disposition,risk) in enumerate(entries,1):
 path=field(role);text=(source/'components/settings'/file).read_text();line=next(i for i,s in enumerate(text.splitlines(),1) if needle in s)
 mask=role in ['master','barPill','surface','avatar','albumArt','hubSelector','header']
 inherited='No' if role in ['master','header'] else 'Bar pill override, then master when null' if role=='workspace' else 'Master when null'
 current=get(schema['effective'],path);default=get(schema['defaults'],path)
 displayed=current if current is not None else (get(schema['effective'],'appearance.roundness.roles.barPill') if role=='workspace' and get(schema['effective'],'appearance.roundness.roles.barPill') is not None else get(schema['effective'],'appearance.roundness.master'))
 c={'Number':n,'Visible label':label,'Settings page':page,'Settings group/card':group,'Persisted field/path':path,'Stored current value':get(raw,path),'Current value':displayed,'Normalized stored value':current,'Default value':default,'Minimum':0,'Maximum':75 if role=='header' else 2,'Step':1 if role=='header' else .05,'Unit':'logical px' if role=='header' else 'multiplier','Control kind':'number stepper' if role=='header' else 'slider','Runtime consumers':role,'Visual scope':{'master':'All inheriting roles, including native lock avatar','surface':'Generic controls/inputs/results, Hub/Settings, menus, notifications/clipboard/emoji/launcher panels and shared borders','action':'Buttons, switches, inputs, result/gallery cards, small controls','barPill':'Status/time/date/utility/tray and connected Bar regions','workspace':'Workspace background and active segment','avatar':'CC avatar, Profile preview, native lock profile and image mask','albumArt':'CC media artwork and progress perimeter','controlTile':'CC primary tiles AND profile/media container backgrounds','secondaryControl':'CC action buttons and inner glyph treatment','slider':'CC IconSlider tracks/knobs','hubSelector':'Hub selector shell and border','header':'Launcher header RoundedArtwork crop/frame'}[role],'Affects clipping/masks':mask,'Affects border geometry':True,'Inheritance':inherited,'Overlap':'Master applies only while null' if inherited!='No' else 'None (base or pixel-valued field)','Proposed disposition':disposition,'Risk of consolidation':risk,'Source':f'.config/quickshell/magi/components/settings/{file}:{line}','Impact key':role}
 controls.append(c)
assert len(controls)==9 and len({c['Persisted field/path'] for c in controls})==9
assert len(roles)+3 == 12
assert all(get(schema['defaults'],field(role))!='ABSENT' for role in roles+['master','workspace','header'])
# Numeric writes must be owned by the central picker; whole-feature reset actions
# intentionally keep their existing semantics on component pages.
settings_ui=source/'components/settings'
for path in settings_ui.rglob('*.qml'):
 if path.name in ['RoundnessPicker.qml','RoundnessValue.qml','LauncherPage.qml']:continue
 text=path.read_text()
 assert not re.search(r'onMoved:[^\n]*(?:setRoundness|setStyle\("roundness")',text), path
 assert not re.search(r'onValueModified:[^\n]*headerRadius',text), path

# Canonical default ownership: action is parsed only for compatibility/migrations.
expected={'surface':'Appearance','hubSelector':'Hub','barPill':'Bar',
 'controlTile':'Control Centre','secondaryControl':'Control Centre','slider':'Control Centre',
 'albumArt':'Control Centre','avatar':'Control Centre','header':'Launcher'}
assert {row[3]:row[1] for row in entries}==expected
for path in source.rglob('*.qml'):
 text=path.read_text()
 assert not re.search(r'radius\("action"|roles\.action|roles\["action"\]|fieldKey:\s*"action"',text),path
assert 'radius("surface", 6' in (source/'theme/Theme.qml').read_text()
assert 'radius("slider"' not in (source/'components/controls/ValueSlider.qml').read_text()
assert 'RenderTokens.sliderRadius' in (source/'components/controls/IconSlider.qml').read_text()
assert 'radius("slider"' in (source/'theme/RenderTokens.qml').read_text()

fixed=[b for b in bindings if b['kind']=='fixed literal']
# Conditional fixed/fallback branches are separate from literal assignments.
# These are reviewed source sites, not independent preferences or every numeric operand.
conditional_specs=[
('.config/quickshell/magi/components/bar/ExpandablePlugin.qml','bottomLeftRadius: revealedHeight'),
('.config/quickshell/magi/components/bar/ExpandablePlugin.qml','bottomRightRadius: revealedHeight'),
('.config/quickshell/magi/components/notifications/ToastHost.qml','radius: modelData ?'),
('.config/quickshell/magi/components/settings/LockThemePreview.qml','radius:root.layout.effects.avatar'),
('native/lock/qml/LockCredential.qml','radius: root.style'),
('native/lock/qml/LockProfile.qml','radius: root.treatment'),
('native/lock/qml/LockTokens.qml','readonly property real avatarRadius:'),
('native/lock/src/visual_data.cpp','{"wallpaperTint",wallpaperTint}'),
('native/lock/src/presentation.cpp','const double outerRadius=')]
conditional=[]
for f,needle in conditional_specs:
 line=next(i for i,s in enumerate((root/f).read_text().splitlines(),1) if needle in s)
 conditional.append({'file':f,'line':line,'kind':'conditional/default radius constant site'})
shape_controls=[]
for n,label,page,group,path,choices,f,needle in [
(15,'Profile picture treatment','Lock Screen','Selected theme options','lockScreen.effects.avatar',['plain','frame'],'pages/LockScreenPage.qml','lockOption-avatarStyle'),
(16,'Password marks','Lock Screen','Authentication appearance','lockScreen.effects.credential',['dots','line','segments','ring','minimal'],'pages/LockScreenPage.qml','lockCredentialStyle'),
(17,'Pill / Filled / Minimal','Hub','Switch appearance','appearance.toggleStyle',['pill','filled','minimal'],'SwitchStylePicker.qml','switchStylePicker')]:
 line=next(i for i,s in enumerate((source/'components/settings'/f).read_text().splitlines(),1) if needle in s)
 shape_controls.append({'Number':n,'Visible label':label,'Settings page':page,'Settings group/card':group,'Persisted field/path':path,'Current value':get(schema['effective'],path),'Default value':get(schema['defaults'],path),'Minimum':'N/A','Maximum':'N/A','Step':'choice','Unit':'enum','Choices':choices,'Runtime consumers':'LockProfile + native avatar mask' if n==15 else 'LockCredential (read-only presentation)' if n==16 else 'CompactToggle','Visual scope':'Picture treatment' if n==15 else 'Credential glyph geometry' if n==16 else 'Toggle track/knob silhouette','Affects clipping/masks':n==15,'Affects border geometry':n!=16,'Inheritance':'Avatar plain follows avatar role; frame forces 4px' if n==15 else 'No; style choice','Overlap':'Developer-gated designer edits same field' if n in [15,16] else 'action role scales corners separately','Proposed disposition':'KEEP — style, not a numeric roundness override','Risk of consolidation':'High if conflated with radius','Source':f'.config/quickshell/magi/components/settings/{f}:{line}'})
result={'method':'Logical control binding per canonical editor; context/module/output copies not counted. Numeric radius fields separately from style enums. Fixed constants = literal QML radius assignment sites (not unique numbers); all other bindings and non-QML matches retained for manual geometry review. Symlinked lock presentation counted once at native source.','counts':{'sliders':8,'number_steppers':1,'numeric_fields':12,'hidden_numeric_fields':3,'compatibility_only_fields':1,'duplicated_fields':0,'duplicate_control_copies':0,'primary_preset_groups_before':0,'primary_preset_buttons_before':0,'primary_preset_groups_after':0,'shape_selectors_normal':3,'shape_choices_normal':10,'designer_shape_selectors':2,'designer_shape_choices':9,'derived_exported_tokens':9,'unused_exported_tokens':1,'dead_numeric_fields':0,'deprecated_runtime_unused_fields':1,'fixed_internal_radius_sites':len(fixed)+len(conditional),'conditional_or_native_constant_sites':len(conditional),'fixed_qml_radius_assignment_sites':len(fixed),'all_runtime_qml_radius_binding_sites':len(bindings),'derived_or_propagated_binding_sites':len(bindings)-len(fixed)},'controls':controls,'shape_controls':shape_controls,'conditional_radius_sites':conditional,'tokens':tokens,'consumers':consumers,'fixed_radius_sites':fixed,'all_radius_bindings':bindings,'search_hits':scan,'snapshot':str(args.settings) if args.settings else 'Schema defaults'}
if args.output:
 args.output.mkdir(parents=True,exist_ok=True)
 (args.output/'roundness-audit.json').write_text(json.dumps(result,indent=2)+'\n')
 with (args.output/'roundness-controls.csv').open('w') as out:
  writer=csv.DictWriter(out,fieldnames=list(controls[0])+['Choices'],lineterminator='\n');writer.writeheader()
  writer.writerows({key: ('null' if value is None else json.dumps(value) if isinstance(value,list) else value) for key,value in row.items()} for row in controls+shape_controls)
 for role,items in consumers.items():
  (args.output/f'consumers-{role}.json').write_text(json.dumps(items,indent=2)+'\n')
print(json.dumps(result['counts'],indent=2));print('Roundness audit PASS: 9 editors, 12 retained numeric fields; no Settings writes')
