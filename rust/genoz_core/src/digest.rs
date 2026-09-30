//! Hash SHA-256 em streaming, usado para integridade e rastreabilidade.

use std::io::Read;

use serde::Serialize;
use sha2::{Digest, Sha256};

use crate::Result;

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct FileDigest {
    /// SHA-256 em hexadecimal minúsculo, calculado sobre os bytes brutos do
    /// arquivo (compactado, se for `.gz`).
    pub sha256: String,
    pub bytes: u64,
}

pub fn sha256_reader<R: Read>(mut reader: R) -> Result<FileDigest> {
    let mut hasher = Sha256::new();
    let mut buf = vec![0u8; 1 << 16];
    let mut bytes = 0u64;
    loop {
        let n = match reader.read(&mut buf) {
            Ok(0) => break,
            Ok(n) => n,
            Err(e) if e.kind() == std::io::ErrorKind::Interrupted => continue,
            Err(e) => return Err(e.into()),
        };
        hasher.update(&buf[..n]);
        bytes += n as u64;
    }
    Ok(FileDigest { sha256: to_hex(&hasher.finalize()), bytes })
}

pub fn sha256_bytes(data: &[u8]) -> String {
    to_hex(&Sha256::digest(data))
}

fn to_hex(bytes: &[u8]) -> String {
    const HEX: &[u8; 16] = b"0123456789abcdef";
    let mut s = String::with_capacity(bytes.len() * 2);
    for b in bytes {
        s.push(HEX[(b >> 4) as usize] as char);
        s.push(HEX[(b & 0xf) as usize] as char);
    }
    s
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn known_vectors() {
        assert_eq!(sha256_bytes(b""), "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855");
        assert_eq!(sha256_bytes(b"abc"), "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    }

    #[test]
    fn streaming_matches_one_shot() {
        let data: Vec<u8> = (0..300_000u32).map(|i| (i % 251) as u8).collect();
        let d = sha256_reader(&data[..]).unwrap();
        assert_eq!(d.sha256, sha256_bytes(&data));
        assert_eq!(d.bytes, data.len() as u64);
    }
}
