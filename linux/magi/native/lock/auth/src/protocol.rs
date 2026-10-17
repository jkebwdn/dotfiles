use crate::{Outcome, secret::Buffer};
use std::os::fd::{AsRawFd, FromRawFd, OwnedFd};
use std::time::{Duration, Instant};
pub const MAX: usize = 512;
pub const HEADER: usize = 12;
pub const LIMIT: u16 = 64;
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u8)]
pub enum Kind {
    Hello = 1,
    HelloAck = 2,
    PromptEchoOff = 3,
    PromptEchoOn = 4,
    Info = 5,
    Error = 6,
    Response = 7,
    AuthenticationResult = 8,
    Cancel = 9,
    Ack = 10,
}
impl Kind {
    fn decode(b: u8) -> Result<Self, Outcome> {
        match b {
            1 => Ok(Self::Hello),
            2 => Ok(Self::HelloAck),
            3 => Ok(Self::PromptEchoOff),
            4 => Ok(Self::PromptEchoOn),
            5 => Ok(Self::Info),
            6 => Ok(Self::Error),
            7 => Ok(Self::Response),
            8 => Ok(Self::AuthenticationResult),
            9 => Ok(Self::Cancel),
            10 => Ok(Self::Ack),
            _ => Err(Outcome::ProtocolError),
        }
    }
    pub fn prompt(self) -> bool {
        matches!(self, Self::PromptEchoOff | Self::PromptEchoOn)
    }
}
pub struct Frame {
    pub kind: Kind,
    pub id: u16,
    data: Buffer,
    len: usize,
}
impl Frame {
    pub fn payload(&self) -> &[u8] {
        &self.data.bytes()[HEADER..HEADER + self.len]
    }
    pub fn parse(data: Buffer, size: usize) -> Result<Self, Outcome> {
        if !(HEADER..=HEADER + MAX).contains(&size) {
            return Err(Outcome::ProtocolError);
        }
        let b = data.bytes();
        if &b[..4] != b"MAG3" || b[4] != 1 {
            return Err(Outcome::ProtocolError);
        }
        let kind = Kind::decode(b[5])?;
        let id = u16::from_be_bytes([b[6], b[7]]);
        let len = u32::from_be_bytes([b[8], b[9], b[10], b[11]]) as usize;
        if len > MAX || size != HEADER + len {
            return Err(Outcome::ProtocolError);
        }
        match kind {
            Kind::Hello | Kind::HelloAck | Kind::Cancel if id != 0 || len != 0 => {
                return Err(Outcome::ProtocolError);
            }
            Kind::AuthenticationResult if id != 0 || len != 1 => {
                return Err(Outcome::ProtocolError);
            }
            Kind::Ack if id == 0 || len != 0 => return Err(Outcome::ProtocolError),
            Kind::Response if id == 0 || len >= MAX || b[HEADER..size].contains(&0) => {
                return Err(Outcome::ProtocolError);
            }
            Kind::PromptEchoOff | Kind::PromptEchoOn | Kind::Info | Kind::Error if id == 0 => {
                return Err(Outcome::ProtocolError);
            }
            _ => (),
        }
        Ok(Self {
            kind,
            id,
            data,
            len,
        })
    }
}
pub struct Channel {
    fd: OwnedFd,
    deadline: Instant,
}
impl Channel {
    pub fn new(fd: OwnedFd, duration: Duration) -> Self {
        Self {
            fd,
            deadline: Instant::now() + duration,
        }
    }
    pub fn fd(&self) -> i32 {
        self.fd.as_raw_fd()
    }
    pub fn pair(duration: Duration) -> Result<(Self, Self), Outcome> {
        let mut fds = [-1; 2];
        // SAFETY: two writable descriptors; ownership transferred only on success.
        if unsafe {
            libc::socketpair(
                libc::AF_UNIX,
                libc::SOCK_SEQPACKET | libc::SOCK_CLOEXEC,
                0,
                fds.as_mut_ptr(),
            )
        } != 0
        {
            return Err(Outcome::WorkerError);
        }
        unsafe {
            Ok((
                Self::new(OwnedFd::from_raw_fd(fds[0]), duration),
                Self::new(OwnedFd::from_raw_fd(fds[1]), duration),
            ))
        }
    }
    fn wait(&self, events: i16) -> Result<(), Outcome> {
        loop {
            let left = self.deadline.saturating_duration_since(Instant::now());
            if left.is_zero() {
                return Err(Outcome::Cancelled);
            }
            let mut p = libc::pollfd {
                fd: self.fd(),
                events,
                revents: 0,
            };
            // SAFETY: valid pollfd, one element, bounded timeout.
            let n = unsafe { libc::poll(&mut p, 1, left.as_millis().min(30_000) as i32) };
            if n == 0 {
                return Err(Outcome::Cancelled);
            }
            if n < 0 {
                if std::io::Error::last_os_error().kind() == std::io::ErrorKind::Interrupted {
                    continue;
                }
                return Err(Outcome::WorkerError);
            }
            if p.revents & events != 0 {
                return Ok(());
            }
            return Err(Outcome::Cancelled);
        }
    }
    pub fn send(&self, kind: Kind, id: u16, payload: &[u8]) -> Result<(), Outcome> {
        if payload.len() > MAX {
            return Err(Outcome::ProtocolError);
        }
        let mut b = Buffer::new(HEADER + MAX);
        let v = b.bytes_mut();
        v[..4].copy_from_slice(b"MAG3");
        v[4] = 1;
        v[5] = kind as u8;
        v[6..8].copy_from_slice(&id.to_be_bytes());
        v[8..12].copy_from_slice(&(payload.len() as u32).to_be_bytes());
        v[HEADER..HEADER + payload.len()].copy_from_slice(payload);
        self.wait(libc::POLLOUT)?;
        // SAFETY: live bounded buffer, MSG_NOSIGNAL prevents SIGPIPE; no ancillary FDs.
        let n = unsafe {
            libc::send(
                self.fd(),
                v.as_ptr().cast(),
                HEADER + payload.len(),
                libc::MSG_NOSIGNAL | libc::MSG_DONTWAIT,
            )
        };
        if n != (HEADER + payload.len()) as isize {
            return Err(Outcome::Cancelled);
        }
        Ok(())
    }
    pub fn recv(&self) -> Result<Frame, Outcome> {
        self.wait(libc::POLLIN)?;
        let mut b = Buffer::new(HEADER + MAX);
        // MSG_TRUNC reports full packet size, so oversized records cannot be accepted.
        let n = unsafe {
            libc::recv(
                self.fd(),
                b.bytes_mut().as_mut_ptr().cast(),
                HEADER + MAX,
                libc::MSG_TRUNC | libc::MSG_DONTWAIT,
            )
        };
        if n <= 0 {
            return Err(Outcome::Cancelled);
        }
        Frame::parse(b, n as usize)
    }
    pub fn expect(&self, kind: Kind, id: u16) -> Result<Frame, Outcome> {
        let f = self.recv()?;
        if f.kind == Kind::Cancel {
            return Err(Outcome::Cancelled);
        }
        if f.kind != kind || f.id != id {
            return Err(Outcome::ProtocolError);
        }
        Ok(f)
    }
    pub fn pending(&self) -> bool {
        let mut p = libc::pollfd {
            fd: self.fd(),
            events: libc::POLLIN,
            revents: 0,
        };
        unsafe { libc::poll(&mut p, 1, 0) != 0 }
    }
}
pub struct Conversation<'a> {
    pub channel: &'a Channel,
    next: u16,
    pub error: Option<Outcome>,
}
impl<'a> Conversation<'a> {
    pub fn new(channel: &'a Channel) -> Self {
        Self {
            channel,
            next: 0,
            error: None,
        }
    }
    pub fn message(&mut self, kind: Kind, text: &[u8]) -> Result<Option<Frame>, Outcome> {
        if self.error.is_some() {
            return Err(self.error.unwrap_or(Outcome::WorkerError));
        }
        let result = self.exchange(kind, text);
        if let Err(e) = result {
            self.error = Some(e);
        }
        result
    }
    fn exchange(&mut self, kind: Kind, text: &[u8]) -> Result<Option<Frame>, Outcome> {
        if self.next >= LIMIT || !(kind.prompt() || matches!(kind, Kind::Info | Kind::Error)) {
            return Err(Outcome::ProtocolError);
        }
        // No response can be queued before the corresponding prompt.
        if self.channel.pending() {
            self.channel.expect(Kind::Cancel, 0)?;
            return Err(Outcome::Cancelled);
        }
        self.next += 1;
        self.channel.send(kind, self.next, text)?;
        let response = self.channel.expect(
            if kind.prompt() {
                Kind::Response
            } else {
                Kind::Ack
            },
            self.next,
        )?;
        Ok(if kind.prompt() { Some(response) } else { None })
    }
}
pub fn serve(channel: &Channel, backend: impl FnOnce(&mut Conversation<'_>) -> Outcome) -> Outcome {
    let result = (|| {
        channel.send(Kind::Hello, 0, &[])?;
        channel.expect(Kind::HelloAck, 0)?;
        let mut conversation = Conversation::new(channel);
        let outcome = backend(&mut conversation);
        if let Some(e) = conversation.error {
            return Err(e);
        }
        if channel.pending() {
            channel.expect(Kind::Cancel, 0)?;
            return Err(Outcome::Cancelled);
        }
        Ok(outcome)
    })()
    .unwrap_or_else(|e| e);
    let _ = channel.send(Kind::AuthenticationResult, 0, &[result as u8]);
    result
}
