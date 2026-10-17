use crate::{Outcome, protocol::Channel};
use std::{
    ffi::{CStr, CString},
    os::{
        fd::{FromRawFd, OwnedFd},
        unix::process::CommandExt,
    },
    process::{Child, Command, Stdio},
    time::Duration,
};
pub const LIFETIME: Duration = Duration::from_secs(120);
pub fn harden() -> Result<(), Outcome> {
    let limit = libc::rlimit {
        rlim_cur: 0,
        rlim_max: 0,
    };
    // No no_new_privs: it could break PAM's existing unix_chkpwd helper.
    if unsafe { libc::setrlimit(libc::RLIMIT_CORE, &limit) } != 0 {
        return Err(Outcome::WorkerError);
    }
    Ok(())
}
pub fn identity() -> Result<CString, Outcome> {
    unsafe {
        let uid = libc::getuid();
        if uid == 0 || uid != libc::geteuid() || libc::getgid() != libc::getegid() {
            return Err(Outcome::WorkerError);
        }
        let mut record: libc::passwd = std::mem::zeroed();
        let mut result = std::ptr::null_mut();
        let mut storage = vec![0u8; 65536];
        if libc::getpwuid_r(
            uid,
            &mut record,
            storage.as_mut_ptr().cast(),
            storage.len(),
            &mut result,
        ) != 0
            || result.is_null()
            || record.pw_name.is_null()
            || record.pw_uid != uid
        {
            return Err(Outcome::WorkerError);
        }
        let name = CStr::from_ptr(record.pw_name);
        if name.is_empty() || name.to_bytes().len() > 256 {
            return Err(Outcome::WorkerError);
        }
        Ok(name.to_owned())
    }
}
/// Takes ownership of FD 3 only after validating it is an unnamed connected
/// AF_UNIX seqpacket socket whose creating peer is the current parent and UID.
pub fn inherited() -> Result<Channel, Outcome> {
    unsafe {
        let mut ty: libc::c_int = 0;
        let mut len = size_of_val(&ty) as libc::socklen_t;
        if libc::getsockopt(
            3,
            libc::SOL_SOCKET,
            libc::SO_TYPE,
            (&mut ty as *mut libc::c_int).cast(),
            &mut len,
        ) != 0
            || ty != libc::SOCK_SEQPACKET
        {
            return Err(Outcome::WorkerError);
        }
        for peer in [false, true] {
            let mut addr: libc::sockaddr_un = std::mem::zeroed();
            let mut n = size_of_val(&addr) as libc::socklen_t;
            let rc = if peer {
                libc::getpeername(3, (&mut addr as *mut libc::sockaddr_un).cast(), &mut n)
            } else {
                libc::getsockname(3, (&mut addr as *mut libc::sockaddr_un).cast(), &mut n)
            };
            if rc != 0
                || addr.sun_family != libc::AF_UNIX as u16
                || n as usize != size_of::<libc::sa_family_t>()
            {
                return Err(Outcome::WorkerError);
            }
        }
        let mut cred: libc::ucred = std::mem::zeroed();
        let mut n = size_of_val(&cred) as libc::socklen_t;
        if libc::getsockopt(
            3,
            libc::SOL_SOCKET,
            libc::SO_PEERCRED,
            (&mut cred as *mut libc::ucred).cast(),
            &mut n,
        ) != 0
            || cred.uid != libc::getuid()
            || cred.pid != libc::getppid()
        {
            return Err(Outcome::WorkerError);
        }
        if libc::fcntl(3, libc::F_SETFD, libc::FD_CLOEXEC) != 0
            || libc::close_range(4, u32::MAX, 0) != 0
        {
            return Err(Outcome::WorkerError);
        }
        // Last-resort lifetime bound if a module never returns to the callback.
        // Normal cancellation unwinds callback and calls pam_end; SIGALRM cannot.
        libc::signal(libc::SIGALRM, libc::SIG_DFL);
        libc::alarm(125);
        Ok(Channel::new(OwnedFd::from_raw_fd(3), LIFETIME))
    }
}
pub struct Worker {
    pub child: Child,
    pub channel: Channel,
}
impl Worker {
    pub fn spawn(mut command: Command) -> Result<Self, Outcome> {
        let (parent, child) = Channel::pair(LIFETIME)?;
        let fd = child.fd();
        command
            .env_clear()
            .env("PATH", "/usr/bin")
            .env("LANG", "C")
            .stdin(Stdio::null())
            .stdout(Stdio::null())
            .stderr(Stdio::piped());
        unsafe {
            command.pre_exec(move || {
                if fd != 3 {
                    if libc::dup2(fd, 3) < 0 {
                        return Err(std::io::Error::last_os_error());
                    }
                } else if libc::fcntl(3, libc::F_SETFD, 0) < 0 {
                    return Err(std::io::Error::last_os_error());
                }
                // Keep Rust's exec error pipe alive until exec, but leak no other FD.
                if libc::close_range(4, u32::MAX, libc::CLOSE_RANGE_CLOEXEC as i32) != 0 {
                    return Err(std::io::Error::last_os_error());
                }
                Ok(())
            });
        }
        let child_process = command.spawn().map_err(|_| Outcome::WorkerError)?;
        drop(child);
        Ok(Self {
            child: child_process,
            channel: parent,
        })
    }
    pub fn finish(&mut self) -> Result<(), Outcome> {
        let deadline = std::time::Instant::now() + Duration::from_secs(2);
        loop {
            match self.child.try_wait() {
                Ok(Some(status)) => {
                    return if status.success() {
                        Ok(())
                    } else {
                        Err(Outcome::WorkerError)
                    };
                }
                Ok(None) if std::time::Instant::now() < deadline => {
                    std::thread::sleep(Duration::from_millis(10))
                }
                _ => return Err(Outcome::WorkerError),
            }
        }
    }
}
impl Drop for Worker {
    fn drop(&mut self) {
        if !matches!(self.child.try_wait(), Ok(Some(_))) {
            let _ = self.child.kill();
        }
        let _ = self.child.wait();
    }
}
