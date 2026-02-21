use aes_gcm::{Aes256Gcm, KeyInit, aead::Aead, Nonce};
use base64::{engine::general_purpose::STANDARD as BASE64, Engine};
use rand::Rng;

pub fn encrypt(plaintext: &str, key: &[u8; 32]) -> Result<(String, String), String> {
    let cipher = Aes256Gcm::new_from_slice(key).map_err(|e| format!("invalid key: {e}"))?;

    // AES-GCM requires a unique nonce per encryption under the same key.
    // We generate a fresh random 96-bit nonce and return it alongside the ciphertext so
    // callers can persist/transmit it for decryption.
    let mut nonce_bytes = [0u8; 12];
    rand::thread_rng().fill(&mut nonce_bytes);
    let nonce = Nonce::from_slice(&nonce_bytes);

    let ciphertext = cipher
        .encrypt(nonce, plaintext.as_bytes())
        .map_err(|e| format!("encryption failed: {e}"))?;

    Ok((BASE64.encode(ciphertext), BASE64.encode(nonce_bytes)))
}

pub fn decrypt(ciphertext_b64: &str, nonce_b64: &str, key: &[u8; 32]) -> Result<String, String> {
    let cipher = Aes256Gcm::new_from_slice(key).map_err(|e| format!("invalid key: {e}"))?;

    let ciphertext = BASE64
        .decode(ciphertext_b64)
        .map_err(|e| format!("ciphertext base64 decode failed: {e}"))?;

    let nonce_raw = BASE64
        .decode(nonce_b64)
        .map_err(|e| format!("nonce base64 decode failed: {e}"))?;

    // A 12-byte (96-bit) nonce is the canonical AES-GCM nonce length.
    if nonce_raw.len() != 12 {
        return Err("nonce must decode to 12 bytes for AES-GCM".to_string());
    }

    let nonce = Nonce::from_slice(&nonce_raw);
    let plaintext_bytes = cipher
        .decrypt(nonce, ciphertext.as_ref())
        .map_err(|e| format!("decryption failed: {e}"))?;

    String::from_utf8(plaintext_bytes).map_err(|e| format!("utf8 decode failed: {e}"))
}
