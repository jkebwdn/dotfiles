use magi_lock_auth::{Outcome, pam, process, protocol, quiet_panic};
fn run() -> Result<(), Outcome> {
    if std::env::args_os().skip(1).collect::<Vec<_>>()
        != ["--ipc-fd=3", "--one-attempt"].map(std::ffi::OsString::from)
    {
        return Err(Outcome::WorkerError);
    }
    if std::env::vars_os()
        .any(|(k, v)| !((k == "PATH" && v == "/usr/bin") || (k == "LANG" && v == "C")))
    {
        return Err(Outcome::WorkerError);
    }
    process::harden()?;
    let user = process::identity()?;
    let channel = process::inherited()?;
    protocol::serve(&channel, |conv| pam::authenticate(conv, &user));
    Ok(()) // Exit status means transport ran; only typed result reports auth.
}
fn main() {
    quiet_panic();
    if run().is_err() {
        eprintln!("WorkerError");
        std::process::exit(1);
    }
}
