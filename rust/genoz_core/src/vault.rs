//! Cofre `.genoz` (Módulo 11, ADR-017): fluxo cifrado com senha.
//!
//! Chave: Argon2id(senha, sal). Dados: XChaCha20-Poly1305 em segmentos de 64 KiB
//! (o desenho de segmentos do GA4GH crypt4gh). Cada segmento autentica o cabeçalho,
//! o próprio índice e a marca de "último": trocar a ordem, cortar o fim ou mexer nos
//! parâmetros é detectado. O nonce de cada segmento é `prefixo (16 bytes) || índice`.
//!
//! O núcleo não sorteia nada: sal e prefixo do nonce vêm de quem chama (gerador
//! seguro do sistema). Leitura e escrita são em fluxo: só um segmento fica na memória.
//!
//! Formato (little-endian):
//! `GENOZVLT` · versão u16 · kdf u16 (1 = Argon2id v1.3) · memória KiB u32 · passadas u32 ·
//! paralelismo u32 · sal [16] · prefixo do nonce [16] · tamanho do segmento u32 ·
//! segmentos (texto cifrado + etiqueta de 16 bytes). Todo segmento, menos o último,
//! tem exatamente o tamanho cheio; o último tem menos (pode ser vazio).

use std::io::{self, Read, Write};

use argon2::{Algorithm, Argon2, Params, Version};
use chacha20poly1305::aead::{Aead, KeyInit, Payload};
use chacha20poly1305::{Key, XChaCha20Poly1305, XNonce};

use crate::error::{GenozError, Result};

pub const MAGIC: &[u8; 8] = b"GENOZVLT";
pub const VAULT_VERSION: u16 = 1;
pub const SEGMENT_SIZE: u32 = 64 * 1024;
const TAG: usize = 16;
const HEADER_LEN: usize = 8 + 2 + 2 + 4 + 4 + 4 + 16 + 16 + 4;

/// Parâmetros do Argon2id. O padrão segue a RFC 9106 (64 MiB, 3 passadas), com
/// paralelismo 1 (o navegador não tem threads para isso).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct KdfParams {
    pub memory_kib: u32,
    pub passes: u32,
    pub parallelism: u32,
}

impl Default for KdfParams {
    fn default() -> Self {
        Self { memory_kib: 64 * 1024, passes: 3, parallelism: 1 }
    }
}

/// Erro de autenticação: senha errada, arquivo alterado ou truncado.
#[derive(Debug)]
pub struct VaultAuthError;

impl std::fmt::Display for VaultAuthError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.write_str("senha incorreta, ou o arquivo foi alterado ou está incompleto")
    }
}

impl std::error::Error for VaultAuthError {}

fn auth_error() -> io::Error {
    io::Error::new(io::ErrorKind::InvalidData, VaultAuthError)
}

/// O erro de E/S é de autenticação do cofre?
pub fn is_auth_error(e: &io::Error) -> bool {
    e.get_ref().is_some_and(|inner| inner.is::<VaultAuthError>())
}

fn derive_key(password: &str, salt: &[u8; 16], p: KdfParams) -> Result<[u8; 32]> {
    let params = Params::new(p.memory_kib, p.passes, p.parallelism, Some(32))
        .map_err(|e| GenozError::InvalidParam(format!("parâmetros do Argon2id: {e}")))?;
    let mut key = [0u8; 32];
    Argon2::new(Algorithm::Argon2id, Version::V0x13, params)
        .hash_password_into(password.as_bytes(), salt, &mut key)
        .map_err(|e| GenozError::InvalidParam(format!("Argon2id: {e}")))?;
    Ok(key)
}

fn header_bytes(p: KdfParams, salt: &[u8; 16], prefix: &[u8; 16], segment: u32) -> [u8; HEADER_LEN] {
    let mut h = [0u8; HEADER_LEN];
    let mut w = &mut h[..];
    w.write_all(MAGIC).expect("cabe");
    w.write_all(&VAULT_VERSION.to_le_bytes()).expect("cabe");
    w.write_all(&1u16.to_le_bytes()).expect("cabe");
    w.write_all(&p.memory_kib.to_le_bytes()).expect("cabe");
    w.write_all(&p.passes.to_le_bytes()).expect("cabe");
    w.write_all(&p.parallelism.to_le_bytes()).expect("cabe");
    w.write_all(salt).expect("cabe");
    w.write_all(prefix).expect("cabe");
    w.write_all(&segment.to_le_bytes()).expect("cabe");
    h
}

struct Cipher {
    aead: XChaCha20Poly1305,
    header: [u8; HEADER_LEN],
    prefix: [u8; 16],
}

impl Cipher {
    fn nonce(&self, index: u64) -> XNonce {
        let mut n = [0u8; 24];
        n[..16].copy_from_slice(&self.prefix);
        n[16..].copy_from_slice(&index.to_le_bytes());
        *XNonce::from_slice(&n)
    }

    fn aad(&self, index: u64, last: bool) -> Vec<u8> {
        let mut a = Vec::with_capacity(HEADER_LEN + 9);
        a.extend_from_slice(&self.header);
        a.extend_from_slice(&index.to_le_bytes());
        a.push(u8::from(last));
        a
    }
}

/// Escreve um cofre em fluxo. Chame [`SealWriter::finish`] no fim (sem ele o
/// arquivo fica sem o último segmento e é recusado na leitura).
pub struct SealWriter<W: Write> {
    out: W,
    cipher: Cipher,
    segment: usize,
    buf: Vec<u8>,
    index: u64,
}

impl<W: Write> SealWriter<W> {
    /// `random` = 16 bytes de sal + 16 bytes de prefixo de nonce, do gerador seguro do sistema.
    pub fn new(mut out: W, password: &str, random: &[u8; 32], params: KdfParams) -> Result<Self> {
        if password.is_empty() {
            return Err(GenozError::InvalidParam("senha vazia".into()));
        }
        let (salt, prefix) = split_random(random);
        let key = derive_key(password, &salt, params)?;
        let header = header_bytes(params, &salt, &prefix, SEGMENT_SIZE);
        out.write_all(&header)?;
        Ok(Self {
            out,
            cipher: Cipher { aead: XChaCha20Poly1305::new(Key::from_slice(&key)), header, prefix },
            segment: SEGMENT_SIZE as usize,
            buf: Vec::with_capacity(SEGMENT_SIZE as usize),
            index: 0,
        })
    }

    fn emit(&mut self, last: bool) -> io::Result<()> {
        let ct = self
            .cipher
            .aead
            .encrypt(
                &self.cipher.nonce(self.index),
                Payload { msg: &self.buf, aad: &self.cipher.aad(self.index, last) },
            )
            .map_err(|_| io::Error::other("falha ao cifrar"))?;
        self.out.write_all(&ct)?;
        self.buf.clear();
        self.index += 1;
        Ok(())
    }

    /// Grava o último segmento e devolve o destino.
    pub fn finish(mut self) -> io::Result<W> {
        if self.buf.len() == self.segment {
            // Segmento cheio nunca é o último: o último vai vazio.
            self.emit(false)?;
        }
        self.emit(true)?;
        self.out.flush()?;
        Ok(self.out)
    }
}

impl<W: Write> Write for SealWriter<W> {
    fn write(&mut self, data: &[u8]) -> io::Result<usize> {
        if data.is_empty() {
            return Ok(0);
        }
        if self.buf.len() == self.segment {
            self.emit(false)?;
        }
        let n = data.len().min(self.segment - self.buf.len());
        self.buf.extend_from_slice(&data[..n]);
        Ok(n)
    }

    fn flush(&mut self) -> io::Result<()> {
        self.out.flush()
    }
}

fn split_random(r: &[u8; 32]) -> ([u8; 16], [u8; 16]) {
    let mut salt = [0u8; 16];
    let mut prefix = [0u8; 16];
    salt.copy_from_slice(&r[..16]);
    prefix.copy_from_slice(&r[16..]);
    (salt, prefix)
}

/// Lê um cofre em fluxo. Erros de autenticação aparecem como `io::Error`
/// reconhecido por [`is_auth_error`].
pub struct OpenReader<R: Read> {
    inner: R,
    cipher: Cipher,
    segment: usize,
    plain: Vec<u8>,
    pos: usize,
    index: u64,
    done: bool,
}

impl<R: Read> OpenReader<R> {
    pub fn new(mut inner: R, password: &str) -> Result<Self> {
        let mut h = [0u8; HEADER_LEN];
        read_exact_or(&mut inner, &mut h).map_err(|_| not_a_vault())?;
        if &h[..8] != MAGIC {
            return Err(not_a_vault());
        }
        let u16_at = |i: usize| u16::from_le_bytes([h[i], h[i + 1]]);
        let u32_at = |i: usize| u32::from_le_bytes([h[i], h[i + 1], h[i + 2], h[i + 3]]);
        let version = u16_at(8);
        if version > VAULT_VERSION {
            return Err(GenozError::InvalidParam(format!(
                "este arquivo .genoz é de uma versão mais nova do Genoz (formato {version}); atualize o app"
            )));
        }
        if u16_at(10) != 1 {
            return Err(not_a_vault());
        }
        let params = KdfParams { memory_kib: u32_at(12), passes: u32_at(16), parallelism: u32_at(20) };
        // Limites contra arquivos montados para travar o aparelho.
        if params.memory_kib > 1024 * 1024 || params.passes > 16 || params.parallelism > 16 {
            return Err(not_a_vault());
        }
        let mut salt = [0u8; 16];
        let mut prefix = [0u8; 16];
        salt.copy_from_slice(&h[24..40]);
        prefix.copy_from_slice(&h[40..56]);
        let segment = u32_at(56);
        if !(1024..=16 * 1024 * 1024).contains(&segment) {
            return Err(not_a_vault());
        }
        let key = derive_key(password, &salt, params)?;
        Ok(Self {
            inner,
            cipher: Cipher { aead: XChaCha20Poly1305::new(Key::from_slice(&key)), header: h, prefix },
            segment: segment as usize,
            plain: Vec::new(),
            pos: 0,
            index: 0,
            done: false,
        })
    }

    fn next_segment(&mut self) -> io::Result<()> {
        let mut chunk = vec![0u8; self.segment + TAG];
        let n = read_up_to(&mut self.inner, &mut chunk)?;
        if n < TAG {
            // Acabou sem o segmento final: truncado.
            return Err(auth_error());
        }
        chunk.truncate(n);
        let last = n < self.segment + TAG;
        self.plain = self
            .cipher
            .aead
            .decrypt(&self.cipher.nonce(self.index), Payload { msg: &chunk, aad: &self.cipher.aad(self.index, last) })
            .map_err(|_| auth_error())?;
        self.pos = 0;
        self.index += 1;
        if last {
            self.done = true;
            let mut extra = [0u8; 1];
            if read_up_to(&mut self.inner, &mut extra)? != 0 {
                return Err(auth_error());
            }
        }
        Ok(())
    }
}

impl<R: Read> Read for OpenReader<R> {
    fn read(&mut self, out: &mut [u8]) -> io::Result<usize> {
        while self.pos == self.plain.len() {
            if self.done {
                return Ok(0);
            }
            self.next_segment()?;
        }
        let n = out.len().min(self.plain.len() - self.pos);
        out[..n].copy_from_slice(&self.plain[self.pos..self.pos + n]);
        self.pos += n;
        Ok(n)
    }
}

fn not_a_vault() -> GenozError {
    GenozError::InvalidParam("não é um arquivo .genoz do Genoz".into())
}

fn read_exact_or<R: Read>(r: &mut R, buf: &mut [u8]) -> io::Result<()> {
    if read_up_to(r, buf)? == buf.len() {
        Ok(())
    } else {
        Err(io::ErrorKind::UnexpectedEof.into())
    }
}

/// Lê até encher `buf` ou o arquivo acabar.
fn read_up_to<R: Read>(r: &mut R, buf: &mut [u8]) -> io::Result<usize> {
    let mut filled = 0;
    while filled < buf.len() {
        match r.read(&mut buf[filled..]) {
            Ok(0) => break,
            Ok(n) => filled += n,
            Err(e) if e.kind() == io::ErrorKind::Interrupted => {}
            Err(e) => return Err(e),
        }
    }
    Ok(filled)
}

/// Cifra bytes na memória (Web e testes).
pub fn seal_bytes(data: &[u8], password: &str, random: &[u8; 32], params: KdfParams) -> Result<Vec<u8>> {
    let mut w = SealWriter::new(Vec::with_capacity(data.len() + data.len() / 4096 + 128), password, random, params)?;
    w.write_all(data)?;
    Ok(w.finish()?)
}

/// Decifra bytes na memória (Web e testes).
pub fn open_bytes(data: &[u8], password: &str) -> Result<Vec<u8>> {
    let mut r = OpenReader::new(data, password)?;
    let mut out = Vec::with_capacity(data.len());
    r.read_to_end(&mut out)?;
    Ok(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    const FAST: KdfParams = KdfParams { memory_kib: 64, passes: 1, parallelism: 1 };
    const RANDOM: [u8; 32] = [7; 32];

    fn data(n: usize) -> Vec<u8> {
        (0..n).map(|i| (i * 31 % 251) as u8).collect()
    }

    #[test]
    fn round_trip_sizes() {
        let s = SEGMENT_SIZE as usize;
        for n in [0, 1, 1000, s - 1, s, s + 1, 2 * s, 3 * s + 17] {
            let d = data(n);
            let sealed = seal_bytes(&d, "senha boa", &RANDOM, FAST).unwrap();
            // Sobrecarga: cabeçalho + 16 bytes por segmento (um a mais quando o tamanho é múltiplo exato).
            let segments = n / s + 1;
            assert_eq!(sealed.len(), HEADER_LEN + n + segments * TAG, "n={n}");
            assert_eq!(open_bytes(&sealed, "senha boa").unwrap(), d, "n={n}");
        }
    }

    #[test]
    fn deterministic_given_random() {
        let d = data(5000);
        assert_eq!(seal_bytes(&d, "x", &RANDOM, FAST).unwrap(), seal_bytes(&d, "x", &RANDOM, FAST).unwrap());
        assert_ne!(seal_bytes(&d, "x", &RANDOM, FAST).unwrap(), seal_bytes(&d, "x", &[8; 32], FAST).unwrap());
    }

    fn auth_fails(sealed: &[u8], pw: &str) -> bool {
        match open_bytes(sealed, pw) {
            Err(GenozError::Io(e)) => is_auth_error(&e),
            _ => false,
        }
    }

    #[test]
    fn wrong_password_tamper_truncate_reorder() {
        let s = SEGMENT_SIZE as usize;
        let d = data(3 * s + 100);
        let sealed = seal_bytes(&d, "certa", &RANDOM, FAST).unwrap();
        assert!(auth_fails(&sealed, "errada"));

        let mut flipped = sealed.clone();
        flipped[HEADER_LEN + 10] ^= 1;
        assert!(auth_fails(&flipped, "certa"));

        // Parâmetro do cabeçalho alterado (autenticado em todo segmento).
        let mut header = sealed.clone();
        header[40] ^= 1; // prefixo do nonce
        assert!(auth_fails(&header, "certa"));

        // Truncado num limite de segmento: o último cheio não vale como final.
        let seg = s + TAG;
        let cut = &sealed[..HEADER_LEN + 2 * seg];
        assert!(auth_fails(cut, "certa"));
        assert!(auth_fails(&sealed[..sealed.len() - 1], "certa"));

        // Segmentos 0 e 1 trocados.
        let mut swapped = sealed.clone();
        let (a, b) = (HEADER_LEN, HEADER_LEN + seg);
        let first = sealed[a..a + seg].to_vec();
        swapped.copy_within(b..b + seg, a);
        swapped[b..b + seg].copy_from_slice(&first);
        assert!(auth_fails(&swapped, "certa"));

        // Lixo depois do fim.
        let mut extra = sealed.clone();
        extra.push(0);
        assert!(auth_fails(&extra, "certa"));
    }

    #[test]
    fn not_a_vault_and_future_version() {
        assert!(matches!(open_bytes(b"##fileformat=VCFv4.3", "x"), Err(GenozError::InvalidParam(_))));
        let mut sealed = seal_bytes(b"oi", "x", &RANDOM, FAST).unwrap();
        sealed[8] = 9;
        let e = open_bytes(&sealed, "x").unwrap_err().to_string();
        assert!(e.contains("versão mais nova"), "{e}");
        assert!(seal_bytes(b"oi", "", &RANDOM, FAST).is_err());
    }

    #[test]
    fn default_params_work() {
        let sealed = seal_bytes(b"genoma", "uma senha", &RANDOM, KdfParams::default()).unwrap();
        assert_eq!(open_bytes(&sealed, "uma senha").unwrap(), b"genoma");
    }
}
