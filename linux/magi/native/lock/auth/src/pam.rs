//! Minimal Linux-PAM ABI, checked against installed 1.7.3 headers.
//! All pointers supplied by libpam/modules are trusted native pointers; this is
//! not isolation from a corrupt module. No PAM calls occur in automated tests.
use crate::{
    Outcome,
    protocol::{Conversation, Kind, MAX},
};
use std::{
    ffi::{CStr, c_char, c_int, c_void},
    ptr,
};
#[repr(C)]
pub struct Message {
    pub style: c_int,
    pub text: *const c_char,
}
#[repr(C)]
pub struct Response {
    pub text: *mut c_char,
    pub code: c_int,
}
#[repr(C)]
struct Conv {
    callback: unsafe extern "C" fn(
        c_int,
        *const *const Message,
        *mut *mut Response,
        *mut c_void,
    ) -> c_int,
    data: *mut c_void,
}
#[link(name = "pam")]
unsafe extern "C" {
    fn pam_start(
        service: *const c_char,
        user: *const c_char,
        conv: *const Conv,
        handle: *mut *mut c_void,
    ) -> c_int;
    fn pam_authenticate(handle: *mut c_void, flags: c_int) -> c_int;
    fn pam_get_item(handle: *const c_void, item: c_int, value: *mut *const c_void) -> c_int;
    fn pam_end(handle: *mut c_void, status: c_int) -> c_int;
}
// Own partial callback responses until all messages succeed. On success PAM owns
// the calloc allocations and must free them. On failure we erase before freeing.
struct Responses {
    ptr: *mut Response,
    count: usize,
}
impl Drop for Responses {
    fn drop(&mut self) {
        if self.ptr.is_null() {
            return;
        }
        unsafe {
            for i in 0..self.count {
                let p = (*self.ptr.add(i)).text;
                if !p.is_null() {
                    libc::explicit_bzero(p.cast(), MAX);
                    libc::free(p.cast());
                }
            }
            libc::free(self.ptr.cast());
        }
    }
}
/// # Safety
/// `messages` points to count valid Linux-PAM message pointers, `out` is writable,
/// and `data` exclusively points to a live Conversation for this callback.
pub unsafe extern "C" fn callback(
    count: c_int,
    messages: *const *const Message,
    out: *mut *mut Response,
    data: *mut c_void,
) -> c_int {
    if out.is_null() || data.is_null() || messages.is_null() || !(1..=32).contains(&count) {
        return 19;
    }
    unsafe {
        *out = ptr::null_mut();
    }
    // No unwind crosses C. Executables install a payload-free panic hook.
    let result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
        let conversation = unsafe { &mut *data.cast::<Conversation<'_>>() };
        let mut responses = Responses {
            ptr: unsafe { libc::calloc(count as usize, size_of::<Response>()).cast() },
            count: count as usize,
        };
        if responses.ptr.is_null() {
            return Err(Outcome::WorkerError);
        }
        for i in 0..count as usize {
            let m = unsafe { *messages.add(i) };
            if m.is_null() {
                return Err(Outcome::PamError);
            }
            let m = unsafe { &*m };
            if m.text.is_null() {
                return Err(Outcome::PamError);
            }
            let kind = match m.style {
                1 => Kind::PromptEchoOff,
                2 => Kind::PromptEchoOn,
                3 => Kind::Error,
                4 => Kind::Info,
                _ => return Err(Outcome::PamError),
            };
            let len = unsafe { libc::strnlen(m.text, MAX + 1) };
            if len > MAX {
                return Err(Outcome::PamError);
            }
            let text = unsafe { std::slice::from_raw_parts(m.text.cast::<u8>(), len) };
            if let Some(frame) = conversation.message(kind, text)? {
                let p = unsafe { libc::calloc(MAX, 1).cast::<c_char>() };
                if p.is_null() {
                    return Err(Outcome::WorkerError);
                }
                unsafe {
                    (*responses.ptr.add(i)).text = p;
                    ptr::copy_nonoverlapping(
                        frame.payload().as_ptr(),
                        p.cast(),
                        frame.payload().len(),
                    );
                }
                // frame drops and erases immediately; calloc supplied final NUL.
            }
        }
        unsafe {
            *out = responses.ptr;
        }
        responses.ptr = ptr::null_mut();
        Ok(())
    }));
    match result {
        Ok(Ok(())) => 0,
        error => {
            let e = match error {
                Ok(Err(e)) => e,
                _ => Outcome::WorkerError,
            };
            unsafe {
                (*data.cast::<Conversation<'_>>()).error = Some(e);
            }
            19
        }
    }
}
struct Transaction {
    handle: *mut c_void,
    status: c_int,
}
impl Drop for Transaction {
    fn drop(&mut self) {
        if !self.handle.is_null() {
            unsafe {
                pam_end(self.handle, self.status);
            }
        }
    }
}
pub fn authenticate(conversation: &mut Conversation<'_>, user: &CStr) -> Outcome {
    // Do not silently fall through to PAM's "other" policy if service disappears.
    if !std::fs::metadata("/etc/pam.d/magi-lock").is_ok_and(|m| m.is_file()) {
        return Outcome::PamError;
    }
    let conv = Conv {
        callback,
        data: (conversation as *mut Conversation<'_>).cast(),
    };
    let mut handle = ptr::null_mut();
    let started = unsafe { pam_start(c"magi-lock".as_ptr(), user.as_ptr(), &conv, &mut handle) };
    if started != 0 {
        return Outcome::PamError;
    }
    let mut transaction = Transaction { handle, status: 4 };
    // PAM_DISALLOW_NULL_AUTHTOK; do not alter PAM delays, credentials or sessions.
    transaction.status = unsafe { pam_authenticate(handle, 1) };
    let auth_status = transaction.status;
    let mut outcome = match auth_status {
        0 => Outcome::Success,
        6 | 7 | 10 | 11 => Outcome::AuthenticationFailed,
        _ => Outcome::PamError,
    };
    if auth_status == 0 {
        let mut value = ptr::null();
        transaction.status = unsafe { pam_get_item(handle, 2, &mut value) };
        // Reject a module switching PAM_USER to any other name, even a UID alias.
        if transaction.status != 0 || value.is_null() {
            outcome = Outcome::PamError;
        } else {
            let p = value.cast::<c_char>();
            let len = unsafe { libc::strnlen(p, 257) };
            if len > 256
                || unsafe { std::slice::from_raw_parts(p.cast::<u8>(), len) } != user.to_bytes()
            {
                outcome = Outcome::AuthenticationFailed;
            }
        }
    }
    let end_status = unsafe { pam_end(handle, transaction.status) };
    transaction.handle = ptr::null_mut();
    if end_status != 0 {
        Outcome::PamError
    } else {
        outcome
    }
}
