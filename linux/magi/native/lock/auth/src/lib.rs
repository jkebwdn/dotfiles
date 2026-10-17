#![deny(unsafe_op_in_unsafe_fn)]
#[cfg(not(all(target_os = "linux", target_env = "gnu")))]
compile_error!("Phase 3 targets Linux/glibc only");
pub mod pam;
pub mod process;
pub mod protocol;
pub mod secret;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u8)]
pub enum Outcome {
    Success = 0,
    AuthenticationFailed = 1,
    Cancelled = 2,
    PamError = 3,
    ProtocolError = 4,
    WorkerError = 5,
}
impl Outcome {
    pub fn decode(b: u8) -> Result<Self, Self> {
        match b {
            0 => Ok(Self::Success),
            1 => Ok(Self::AuthenticationFailed),
            2 => Ok(Self::Cancelled),
            3 => Ok(Self::PamError),
            4 => Ok(Self::ProtocolError),
            5 => Ok(Self::WorkerError),
            _ => Err(Self::ProtocolError),
        }
    }
}
pub fn quiet_panic() {
    std::panic::set_hook(Box::new(|_| eprintln!("WorkerError")));
}
