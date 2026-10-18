//! Test-only peer for C++ integration; never installed; development crash/hang selection is explicitly gated.
//! Uses the production Rust IPC implementation, never calls any PAM entry point.
use magi_lock_auth::{
    Outcome, process,
    protocol::{self, Kind},
};
fn main() {
    magi_lock_auth::quiet_panic();
    process::harden().expect("fixture core limit");
    let name = std::env::args().next().unwrap_or_default();
    let mode = std::path::Path::new(&name)
        .file_name()
        .and_then(|s| s.to_str())
        .unwrap_or("");
    if !mode.starts_with("fixture-") {
        std::process::exit(64);
    }
    let channel = process::inherited().expect("fixture descriptor");
    if mode == "fixture-crash" {
        std::process::abort();
    }
    if mode == "fixture-exitonly" {
        return;
    }
    if mode == "fixture-hang" {
        std::thread::sleep(std::time::Duration::from_secs(300));
        return;
    }
    if [
        "fixture-version",
        "fixture-truncated",
        "fixture-oversize",
        "fixture-unknown",
    ]
    .contains(&mode)
    {
        let mut data = [0u8; 600];
        data[..4].copy_from_slice(b"MAG3");
        data[4] = 1;
        data[5] = 1;
        let n = match mode {
            "fixture-version" => {
                data[4] = 2;
                12
            }
            "fixture-truncated" => 5,
            "fixture-oversize" => 600,
            _ => {
                data[5] = 99;
                12
            }
        };
        unsafe {
            libc::send(channel.fd(), data.as_ptr().cast(), n, libc::MSG_NOSIGNAL);
        }
        return;
    }
    if matches!(
        mode,
        "fixture-eof-handshake" | "fixture-eof-prompt" | "fixture-eof-response"
    ) {
        channel.send(Kind::Hello, 0, &[]).unwrap();
        channel.expect(Kind::HelloAck, 0).unwrap();
        if mode == "fixture-eof-handshake" {
            return;
        }
        channel.send(Kind::PromptEchoOff, 1, b"synthetic").unwrap();
        if mode == "fixture-eof-response" {
            let _ = channel.expect(Kind::Response, 1);
        }
        return;
    }
    if mode == "fixture-wrongid" {
        channel.send(Kind::Hello, 0, &[]).unwrap();
        channel.expect(Kind::HelloAck, 0).unwrap();
        channel.send(Kind::PromptEchoOff, 2, b"synthetic").unwrap();
        return;
    }
    protocol::serve(&channel, |conversation| {
        if mode == "fixture-zero-success" {
            return Outcome::Success;
        }
        if mode == "fixture-echoon" {
            let _ = conversation.message(Kind::PromptEchoOn, b"synthetic");
            return Outcome::Success;
        }
        for kind in [Kind::Info, Kind::Error, Kind::PromptEchoOff] {
            match conversation.message(kind, b"synthetic") {
                Ok(Some(frame)) => {
                    if frame.payload() != b"MAGI_TEST_SECRET_7df1_CPP" {
                        return Outcome::AuthenticationFailed;
                    }
                }
                Ok(None) => (),
                Err(e) => return e,
            }
        }
        if mode == "fixture-secondprompt" {
            let _ = conversation.message(Kind::PromptEchoOff, b"second");
        }
        if mode == "fixture-delayed-success" {
            std::thread::sleep(std::time::Duration::from_millis(250));
        }
        match mode {
            "fixture-protocolerror" => Outcome::ProtocolError,
            "fixture-workererror" => Outcome::WorkerError,
            "fixture-cancelled" => Outcome::Cancelled,
            "fixture-failed" => Outcome::AuthenticationFailed,
            "fixture-pamerror" => Outcome::PamError,
            _ => Outcome::Success,
        }
    });
    if mode == "fixture-result-hang" {
        std::thread::sleep(std::time::Duration::from_secs(300));
    }
    if mode == "fixture-success-crash" {
        std::process::abort();
    }
    if mode == "fixture-duplicate" {
        let _ = channel.send(Kind::AuthenticationResult, 0, &[0]);
    }
    if mode == "fixture-extraframe" {
        let _ = channel.send(Kind::Hello, 0, &[]);
    }
    if mode == "fixture-badexit" {
        std::process::exit(1);
    }
}
