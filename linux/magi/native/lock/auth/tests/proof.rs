use magi_lock_auth::{
    Outcome,
    pam::{self, Message, Response},
    process::{self, Worker},
    protocol::{self, Channel, HEADER, Kind, MAX},
    secret::Buffer,
};
use std::{ffi::CString, io::Read, process::Command, ptr, time::Duration};
const SECRET: &[u8] = b"MAGI_TEST_SECRET_7df1_synthetic_only";
fn pair() -> (Channel, Channel) {
    Channel::pair(Duration::from_secs(3)).unwrap()
}
fn raw(channel: &Channel, packet: &[u8]) {
    assert_eq!(
        unsafe {
            libc::send(
                channel.fd(),
                packet.as_ptr().cast(),
                packet.len(),
                libc::MSG_NOSIGNAL,
            )
        },
        packet.len() as isize
    );
}
fn packet(kind: u8, id: u16, payload: &[u8]) -> Vec<u8> {
    let mut b = b"MAG3".to_vec();
    b.extend([1, kind]);
    b.extend(id.to_be_bytes());
    b.extend((payload.len() as u32).to_be_bytes());
    b.extend(payload);
    b
}
#[test]
fn framing_rejects_version_truncation_size_unknown_and_nul() {
    let mut version = packet(7, 1, SECRET);
    version[4] = 2;
    let mut length = packet(7, 1, SECRET);
    length[11] += 1;
    for b in [
        version,
        length,
        vec![1, 2, 3],
        packet(99, 1, SECRET),
        packet(7, 1, &vec![42; MAX + 1]),
        packet(7, 1, b"a\0b"),
        packet(9, 1, &[]),
    ] {
        let (a, bch) = pair();
        raw(&a, &b);
        assert!(matches!(bch.recv(), Err(Outcome::ProtocolError)));
    }
}
#[test]
fn closed_socket_and_timeout() {
    let (a, b) = pair();
    drop(a);
    assert!(matches!(b.recv(), Err(Outcome::Cancelled)));
    let (_a, b) = Channel::pair(Duration::from_millis(10)).unwrap();
    assert!(matches!(b.recv(), Err(Outcome::Cancelled)));
}
#[test]
fn wrong_handshake_never_calls_backend() {
    for kind in [Kind::Response, Kind::Hello, Kind::Ack] {
        let (a, b) = pair();
        let t = std::thread::spawn(move || protocol::serve(&b, |_| panic!("backend must not run")));
        a.expect(Kind::Hello, 0).unwrap();
        a.send(kind, 1, SECRET).unwrap();
        assert_eq!(
            a.expect(Kind::AuthenticationResult, 0).unwrap().payload(),
            &[Outcome::ProtocolError as u8]
        );
        assert_eq!(t.join().unwrap(), Outcome::ProtocolError);
    }
}
// Fake PAM backend calls the *real FFI callback* with a Linux-PAM pointer array.
// This covers batches, styles, partial-response cleanup and owned C allocations.
fn fake(conv: &mut protocol::Conversation<'_>, styles: &[i32]) -> Outcome {
    let text = CString::new("synthetic prompt").unwrap();
    let messages: Vec<_> = styles
        .iter()
        .map(|style| Message {
            style: *style,
            text: text.as_ptr(),
        })
        .collect();
    let pointers: Vec<_> = messages.iter().map(|m| m as *const Message).collect();
    let mut output: *mut Response = ptr::null_mut();
    let rc = unsafe {
        pam::callback(
            styles.len() as i32,
            pointers.as_ptr(),
            &mut output,
            (conv as *mut protocol::Conversation<'_>).cast(),
        )
    };
    if rc != 0 {
        assert!(output.is_null());
        return Outcome::PamError;
    }
    assert!(!output.is_null());
    unsafe {
        for (i, style) in styles.iter().enumerate() {
            let r = &*output.add(i);
            assert_eq!(r.code, 0);
            if *style == 1 || *style == 2 {
                assert!(!r.text.is_null());
                // Never include secret in assertion diagnostics.
                assert!(std::ffi::CStr::from_ptr(r.text).to_bytes() == SECRET);
                libc::explicit_bzero(r.text.cast(), MAX);
                assert!(
                    std::slice::from_raw_parts(r.text.cast::<u8>(), MAX)
                        .iter()
                        .all(|b| *b == 0)
                );
                libc::free(r.text.cast());
            } else {
                assert!(r.text.is_null());
            }
        }
        libc::free(output.cast());
    }
    Outcome::Success
}
fn handshake(a: &Channel) {
    a.expect(Kind::Hello, 0).unwrap();
    a.send(Kind::HelloAck, 0, &[]).unwrap();
}
fn answer(a: &Channel, kind: Kind, id: u16) {
    a.expect(kind, id).unwrap();
    a.send(
        if kind.prompt() {
            Kind::Response
        } else {
            Kind::Ack
        },
        id,
        if kind.prompt() { SECRET } else { &[] },
    )
    .unwrap();
}
#[test]
fn all_styles_batch_multiple_prompts_and_success() {
    let (a, b) = pair();
    let t = std::thread::spawn(move || protocol::serve(&b, |c| fake(c, &[1, 2, 4, 3, 1])));
    handshake(&a);
    for (i, kind) in [
        Kind::PromptEchoOff,
        Kind::PromptEchoOn,
        Kind::Info,
        Kind::Error,
        Kind::PromptEchoOff,
    ]
    .into_iter()
    .enumerate()
    {
        answer(&a, kind, i as u16 + 1);
    }
    assert_eq!(
        a.expect(Kind::AuthenticationResult, 0).unwrap().payload(),
        &[0]
    );
    assert_eq!(t.join().unwrap(), Outcome::Success);
}
#[test]
fn cancellation_bad_order_oversize_disconnect_partial_batch_cleanup() {
    for mode in 0..6 {
        let (a, b) = pair();
        let t = std::thread::spawn(move || protocol::serve(&b, |c| fake(c, &[1, 1])));
        handshake(&a);
        answer(&a, Kind::PromptEchoOff, 1);
        a.expect(Kind::PromptEchoOff, 2).unwrap();
        let expected = match mode {
            0 => {
                a.send(Kind::Cancel, 0, &[]).unwrap();
                Outcome::Cancelled
            }
            1 => {
                a.send(Kind::Response, 1, SECRET).unwrap();
                Outcome::ProtocolError
            }
            2 => {
                raw(&a, &packet(7, 2, &vec![42; MAX + 1]));
                Outcome::ProtocolError
            }
            3 => {
                a.send(Kind::Ack, 2, &[]).unwrap();
                Outcome::ProtocolError
            }
            4 => {
                raw(&a, b"MAG3");
                Outcome::ProtocolError
            }
            _ => {
                drop(a);
                assert_eq!(t.join().unwrap(), Outcome::Cancelled);
                continue;
            }
        };
        assert_eq!(
            a.expect(Kind::AuthenticationResult, 0).unwrap().payload(),
            &[expected as u8]
        );
        assert_eq!(t.join().unwrap(), expected);
    }
}
#[test]
fn failed_backend_and_invalid_pam_style() {
    for invalid in [false, true] {
        let (a, b) = pair();
        let t = std::thread::spawn(move || {
            protocol::serve(&b, |c| {
                if invalid {
                    fake(c, &[99])
                } else {
                    Outcome::AuthenticationFailed
                }
            })
        });
        handshake(&a);
        let expected = if invalid {
            Outcome::PamError
        } else {
            Outcome::AuthenticationFailed
        };
        assert_eq!(
            a.expect(Kind::AuthenticationResult, 0).unwrap().payload(),
            &[expected as u8]
        );
        assert_eq!(t.join().unwrap(), expected);
    }
}
#[test]
fn startup_cancel_does_not_call_backend() {
    let (a, b) = pair();
    let t = std::thread::spawn(move || protocol::serve(&b, |_| panic!("must not run")));
    a.expect(Kind::Hello, 0).unwrap();
    a.send(Kind::Cancel, 0, &[]).unwrap();
    assert_eq!(
        a.expect(Kind::AuthenticationResult, 0).unwrap().payload(),
        &[2]
    );
    assert_eq!(t.join().unwrap(), Outcome::Cancelled);
}
#[test]
fn bounded_frames_and_result_codes() {
    for code in 0..=255 {
        assert_eq!(Outcome::decode(code).is_ok(), code <= 5);
    }
    let mut buf = Buffer::new(HEADER + MAX);
    buf.bytes_mut()[..4].copy_from_slice(b"MAG3");
    assert!(protocol::Frame::parse(buf, HEADER + MAX + 1).is_err());
}
// Child fixtures exist only in this Cargo integration test executable. The
// shipped worker contains no fake backend or fake-success CLI/environment flag.
fn child_fixture(panic_case: bool) {
    if !std::env::args().any(|arg| arg == "--exact") {
        return;
    }
    let Ok(channel) = process::inherited() else {
        return;
    }; // ordinary test runner
    magi_lock_auth::quiet_panic();
    process::harden().unwrap();
    protocol::serve(&channel, |c| {
        if panic_case {
            let _ = std::panic::catch_unwind(|| {
                std::panic::panic_any(SECRET);
            });
            Outcome::WorkerError
        } else {
            fake(c, &[1, 2, 4, 3, 1])
        }
    });
}
#[test]
fn child_success_fixture() {
    child_fixture(false);
}
#[test]
fn child_panic_fixture() {
    child_fixture(true);
}
#[test]
fn inherited_spawn_exit_and_secret_output_regression() {
    for panic_case in [false, true] {
        let mut cmd = Command::new(std::env::current_exe().unwrap());
        cmd.args([
            "--exact",
            if panic_case {
                "child_panic_fixture"
            } else {
                "child_success_fixture"
            },
            "--nocapture",
        ]);
        let mut worker = Worker::spawn(cmd).unwrap();
        handshake(&worker.channel);
        if !panic_case {
            for (i, kind) in [
                Kind::PromptEchoOff,
                Kind::PromptEchoOn,
                Kind::Info,
                Kind::Error,
                Kind::PromptEchoOff,
            ]
            .into_iter()
            .enumerate()
            {
                answer(&worker.channel, kind, i as u16 + 1);
            }
        }
        assert_eq!(
            worker
                .channel
                .expect(Kind::AuthenticationResult, 0)
                .unwrap()
                .payload(),
            &[if panic_case { 5 } else { 0 }]
        );
        worker.finish().unwrap();
        let mut stderr = Vec::new();
        worker
            .child
            .stderr
            .take()
            .unwrap()
            .read_to_end(&mut stderr)
            .unwrap();
        assert!(!stderr.windows(SECRET.len()).any(|w| w == SECRET));
        if panic_case {
            assert!(stderr.windows(11).any(|w| w == b"WorkerError"));
        }
    }
}
#[test]
fn binaries_reject_ungated_startup_without_pam() {
    for binary in [
        env!("CARGO_BIN_EXE_magi-lock-auth"),
        env!("CARGO_BIN_EXE_magi-auth-harness"),
    ] {
        let output = Command::new(binary).output().unwrap();
        assert!(!output.status.success());
        for text in [&output.stdout, &output.stderr] {
            assert!(!text.windows(SECRET.len()).any(|w| w == SECRET));
        }
    }
}

#[test]
fn real_worker_cancelled_before_pam_start() {
    // This deliberately never sends HelloAck: serve cannot call its backend.
    let mut cmd = Command::new(env!("CARGO_BIN_EXE_magi-lock-auth"));
    cmd.args(["--ipc-fd=3", "--one-attempt"]);
    let mut worker = Worker::spawn(cmd).unwrap();
    worker.channel.expect(Kind::Hello, 0).unwrap();
    worker.channel.send(Kind::Cancel, 0, &[]).unwrap();
    assert_eq!(
        worker
            .channel
            .expect(Kind::AuthenticationResult, 0)
            .unwrap()
            .payload(),
        &[2]
    );
    worker.finish().unwrap();
}

#[test]
fn prompt_limit_and_unsolicited_response() {
    let (a, b) = pair();
    let t = std::thread::spawn(move || {
        protocol::serve(&b, |c| {
            for _ in 0..=protocol::LIMIT {
                if c.message(Kind::Info, b"synthetic").is_err() {
                    break;
                }
            }
            Outcome::Success
        })
    });
    handshake(&a);
    for id in 1..=protocol::LIMIT {
        answer(&a, Kind::Info, id);
    }
    assert_eq!(
        a.expect(Kind::AuthenticationResult, 0).unwrap().payload(),
        &[4]
    );
    assert_eq!(t.join().unwrap(), Outcome::ProtocolError);
    let (a, b) = pair();
    a.send(Kind::Response, 1, SECRET).unwrap();
    let mut conv = protocol::Conversation::new(&b);
    assert!(matches!(
        conv.message(Kind::PromptEchoOff, b"prompt"),
        Err(Outcome::ProtocolError)
    ));
}

#[test]
fn child_stuck_fixture() {
    if !std::env::args().any(|arg| arg == "--exact") {
        return;
    }
    let channel = process::inherited().unwrap();
    assert_ne!(
        unsafe { libc::fcntl(3, libc::F_GETFD) } & libc::FD_CLOEXEC,
        0
    );
    channel.send(Kind::Hello, 0, &[]).unwrap();
    // Simulate a module that does not return. No PAM entry point is called.
    unsafe {
        libc::pause();
    }
}

#[test]
fn dropping_parent_worker_kills_and_reaps_stuck_child() {
    let mut cmd = Command::new(std::env::current_exe().unwrap());
    cmd.args(["--exact", "child_stuck_fixture", "--nocapture"]);
    let worker = Worker::spawn(cmd).unwrap();
    worker.channel.expect(Kind::Hello, 0).unwrap();
    let pid = worker.child.id() as i32;
    drop(worker);
    let mut status = 0;
    assert_eq!(
        unsafe { libc::waitpid(pid, &mut status, libc::WNOHANG) },
        -1
    );
    assert_eq!(
        std::io::Error::last_os_error().raw_os_error(),
        Some(libc::ECHILD)
    );
}
