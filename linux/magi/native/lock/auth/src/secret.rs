// Fixed allocation: no growth, Clone, Debug, Display, or String conversion.
// glibc explicit_bzero is an out-of-line, non-elidable erase primitive.
pub struct Buffer(Box<[u8]>);
impl Buffer {
    pub fn new(size: usize) -> Self {
        Self(vec![0; size].into_boxed_slice())
    }
    pub fn bytes(&self) -> &[u8] {
        &self.0
    }
    pub fn bytes_mut(&mut self) -> &mut [u8] {
        &mut self.0
    }
    pub fn clear(&mut self) {
        // SAFETY: allocation is live and exclusively borrowed for its full length.
        unsafe { libc::explicit_bzero(self.0.as_mut_ptr().cast(), self.0.len()) }
    }
}
impl Drop for Buffer {
    fn drop(&mut self) {
        self.clear();
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn wipe_owned_storage() {
        let mut b = Buffer::new(512);
        b.bytes_mut().fill(42);
        b.clear();
        assert!(b.bytes().iter().all(|b| *b == 0));
    }
}
