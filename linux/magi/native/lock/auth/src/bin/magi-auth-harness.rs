//! Non-locking native parent. No stdin/argv/environment credential input.
use magi_lock_auth::{
    Outcome,
    process::{self, Worker},
    protocol::{Channel, Kind, LIMIT, MAX},
    secret::Buffer,
};
use std::{
    fs::{File, OpenOptions},
    io::Write,
    os::fd::AsRawFd,
    process::Command,
    sync::atomic::{AtomicBool, Ordering},
    time::Instant,
};
static INTERRUPTED: AtomicBool = AtomicBool::new(false);
extern "C" fn interrupt(_: i32) {
    INTERRUPTED.store(true, Ordering::Relaxed);
}
struct Terminal {
    file: File,
    original: libc::termios,
}
impl Terminal {
    fn open() -> Result<Self, Outcome> {
        let file = OpenOptions::new()
            .read(true)
            .write(true)
            .open("/dev/tty")
            .map_err(|_| Outcome::WorkerError)?;
        Self::from_file(file)
    }
    fn from_file(file: File) -> Result<Self, Outcome> {
        let mut original = unsafe { std::mem::zeroed() };
        if unsafe { libc::tcgetattr(file.as_raw_fd(), &mut original) } != 0 {
            return Err(Outcome::WorkerError);
        }
        let terminal = Self { file, original };
        let mut mode = original;
        mode.c_lflag &= !(libc::ECHO | libc::ECHONL | libc::ICANON | libc::ISIG | libc::IEXTEN);
        mode.c_cc[libc::VMIN] = 1;
        mode.c_cc[libc::VTIME] = 0;
        if unsafe { libc::tcsetattr(terminal.file.as_raw_fd(), libc::TCSAFLUSH, &mode) } != 0 {
            return Err(Outcome::WorkerError);
        }
        Ok(terminal)
    }
    fn read(&mut self, channel: &Channel, deadline: Instant) -> Result<(Buffer, usize), Outcome> {
        let mut buffer = Buffer::new(MAX);
        let mut len = 0;
        loop {
            if INTERRUPTED.load(Ordering::Relaxed) || Instant::now() >= deadline {
                return Err(Outcome::Cancelled);
            }
            let mut polls = [
                libc::pollfd {
                    fd: self.file.as_raw_fd(),
                    events: libc::POLLIN,
                    revents: 0,
                },
                libc::pollfd {
                    fd: channel.fd(),
                    events: libc::POLLIN,
                    revents: 0,
                },
            ];
            let rc = unsafe { libc::poll(polls.as_mut_ptr(), 2, 100) };
            if rc < 0 {
                if std::io::Error::last_os_error().kind() == std::io::ErrorKind::Interrupted {
                    continue;
                }
                return Err(Outcome::WorkerError);
            }
            if polls[1].revents != 0 {
                return Err(Outcome::Cancelled);
            }
            if polls[0].revents == 0 {
                continue;
            }
            if polls[0].revents & libc::POLLIN == 0 {
                return Err(Outcome::Cancelled);
            }
            let slot = &mut buffer.bytes_mut()[len];
            if unsafe { libc::read(self.file.as_raw_fd(), (slot as *mut u8).cast(), 1) } != 1 {
                return Err(Outcome::Cancelled);
            }
            match *slot {
                b'\n' | b'\r' => {
                    *slot = 0;
                    return Ok((buffer, len));
                }
                3 | 4 | 27 => return Err(Outcome::Cancelled), // Ctrl-C, Ctrl-D, Escape
                8 | 127 => {
                    *slot = 0;
                    if len > 0 {
                        len -= 1;
                        buffer.bytes_mut()[len] = 0;
                    }
                }
                0 => return Err(Outcome::ProtocolError),
                _ => {
                    len += 1;
                    if len >= MAX {
                        return Err(Outcome::ProtocolError);
                    }
                }
            }
        }
    }
}
impl Drop for Terminal {
    fn drop(&mut self) {
        unsafe {
            libc::tcsetattr(self.file.as_raw_fd(), libc::TCSAFLUSH, &self.original);
        }
    }
}
fn run() -> Result<Outcome, Outcome> {
    if std::env::args().skip(1).collect::<Vec<_>>() != ["--real-pam", "--operator-approved"] {
        eprintln!(
            "Usage (only after explicit approval): magi-auth-harness --real-pam --operator-approved"
        );
        return Err(Outcome::WorkerError);
    }
    process::harden()?;
    let _user = process::identity()?;
    unsafe {
        for signal in [libc::SIGINT, libc::SIGTERM, libc::SIGHUP, libc::SIGTSTP] {
            let mut action: libc::sigaction = std::mem::zeroed();
            action.sa_sigaction = interrupt as *const () as usize;
            libc::sigemptyset(&mut action.sa_mask);
            if libc::sigaction(signal, &action, std::ptr::null_mut()) != 0 {
                return Err(Outcome::WorkerError);
            }
        }
    }
    let mut terminal = Terminal::open()?;
    writeln!(terminal.file, "Non-locking PAM proof: one attempt, current UID, service magi-lock.\r\nAll responses hidden; Ctrl-C/Escape cancels. Starting in 3 seconds.").map_err(|_| Outcome::WorkerError)?;
    // Interactive-only, one launch, no retry loop. This is an accident guard,
    // not a replacement for PAM faillock or future owner-side serialization.
    for _ in 0..30 {
        if INTERRUPTED.load(Ordering::Relaxed) {
            return Err(Outcome::Cancelled);
        }
        std::thread::sleep(std::time::Duration::from_millis(100));
    }
    let mut path = std::env::current_exe().map_err(|_| Outcome::WorkerError)?;
    path.set_file_name("magi-lock-auth");
    let mut command = Command::new(path);
    command.args(["--ipc-fd=3", "--one-attempt"]);
    let mut worker = Worker::spawn(command)?;
    let deadline = Instant::now() + process::LIFETIME;
    let result = (|| {
        worker.channel.expect(Kind::Hello, 0)?;
        worker.channel.send(Kind::HelloAck, 0, &[])?;
        let mut id = 0;
        loop {
            if INTERRUPTED.load(Ordering::Relaxed) {
                return Err(Outcome::Cancelled);
            }
            let frame = worker.channel.recv()?;
            if INTERRUPTED.load(Ordering::Relaxed) {
                return Err(Outcome::Cancelled);
            }
            if frame.kind == Kind::AuthenticationResult {
                return Outcome::decode(frame.payload()[0]);
            }
            if id >= LIMIT || frame.id != id + 1 {
                return Err(Outcome::ProtocolError);
            }
            id += 1;
            match frame.kind {
                Kind::PromptEchoOff | Kind::PromptEchoOn => {
                    // Do not print raw PAM text, even for informational messages.
                    writeln!(terminal.file, "{:?}: enter response (hidden):", frame.kind)
                        .map_err(|_| Outcome::WorkerError)?;
                    let (mut response, len) = terminal.read(&worker.channel, deadline)?;
                    let sent = worker
                        .channel
                        .send(Kind::Response, id, &response.bytes()[..len]);
                    response.clear();
                    sent?;
                }
                Kind::Info | Kind::Error => {
                    writeln!(terminal.file, "PAM {:?}", frame.kind)
                        .map_err(|_| Outcome::WorkerError)?;
                    worker.channel.send(Kind::Ack, id, &[])?;
                }
                _ => return Err(Outcome::ProtocolError),
            }
        }
    })();
    if result.is_err() {
        let _ = worker.channel.send(Kind::Cancel, 0, &[]);
    }
    // Restore before any wait or diagnostic. Drop also restores on early returns.
    drop(terminal);
    let finished = worker.finish(); // 2-second grace, Drop kills/reaps a stuck child.
    match result {
        Ok(outcome) => {
            finished?;
            Ok(outcome)
        }
        Err(e) => Err(e),
    }
}
fn main() {
    magi_lock_auth::quiet_panic();
    let outcome = run().unwrap_or_else(|e| e);
    println!("{outcome:?}");
    if outcome != Outcome::Success {
        std::process::exit(1);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::os::fd::FromRawFd;
    #[test]
    fn synthetic_tty_input_hidden_and_restored_on_success_and_cancel() {
        for cancel in [false, true] {
            let (mut master, mut slave) = (-1, -1);
            assert_eq!(
                unsafe {
                    libc::openpty(
                        &mut master,
                        &mut slave,
                        std::ptr::null_mut(),
                        std::ptr::null(),
                        std::ptr::null(),
                    )
                },
                0
            );
            let mut master = unsafe { File::from_raw_fd(master) };
            let slave = unsafe { File::from_raw_fd(slave) };
            let observer = slave.try_clone().unwrap();
            let mut before: libc::termios = unsafe { std::mem::zeroed() };
            assert_eq!(
                unsafe { libc::tcgetattr(observer.as_raw_fd(), &mut before) },
                0
            );
            let mut terminal = Terminal::from_file(slave).unwrap();
            let mut during: libc::termios = unsafe { std::mem::zeroed() };
            assert_eq!(
                unsafe { libc::tcgetattr(observer.as_raw_fd(), &mut during) },
                0
            );
            assert_eq!(during.c_lflag & (libc::ECHO | libc::ECHONL), 0);
            let secret = b"MAGI_TEST_SECRET_7df1_tty";
            master.write_all(secret).unwrap();
            master
                .write_all(if cancel { b"\x03" } else { b"\n" })
                .unwrap();
            let (channel, _peer) = Channel::pair(std::time::Duration::from_secs(1)).unwrap();
            let result =
                terminal.read(&channel, Instant::now() + std::time::Duration::from_secs(1));
            if cancel {
                assert!(matches!(result, Err(Outcome::Cancelled)));
            } else {
                let (b, n) = result.unwrap();
                assert!(b.bytes()[..n] == *secret);
            }
            drop(terminal);
            let mut after: libc::termios = unsafe { std::mem::zeroed() };
            assert_eq!(
                unsafe { libc::tcgetattr(observer.as_raw_fd(), &mut after) },
                0
            );
            assert_eq!(after.c_lflag, before.c_lflag);
            let mut poll = libc::pollfd {
                fd: master.as_raw_fd(),
                events: libc::POLLIN,
                revents: 0,
            };
            assert_eq!(
                unsafe { libc::poll(&mut poll, 1, 0) },
                0,
                "TTY must not echo input"
            );
        }
    }
}
