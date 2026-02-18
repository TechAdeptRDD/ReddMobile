use aes_gcm::aead::Aead;
use aes_gcm::{Aes256Gcm, KeyInit, Nonce};
use base64::engine::general_purpose::STANDARD;
use base64::Engine;
use rand::RngCore;

pub fn encrypt(plaintext: &str, key: &[u8; 32]) -> Result<(String, String), String> {
    let cipher = Aes256Gcm::new_from_slice(key).map_err(|e| format!("invalid key: {e}"))?;

    let mut nonce_bytes = [0u8; 12];
    rand::thread_rng().fill_bytes(&mut nonce_bytes);
    let nonce = Nonce::from_slice(&nonce_bytes);

    let ciphertext = cipher
        .encrypt(nonce, plaintext.as_bytes())
        .map_err(|e| format!("encryption failed: {e}"))?;

    Ok((STANDARD.encode(ciphertext), STANDARD.encode(nonce_bytes)))
}

pub fn decrypt(ciphertext_b64: &str, nonce_b64: &str, key: &[u8; 32]) -> Result<String, String> {
    let cipher = Aes256Gcm::new_from_slice(key).map_err(|e| format!("invalid key: {e}"))?;

    let ciphertext = STANDARD
        .decode(ciphertext_b64)
        .map_err(|e| format!("ciphertext base64 decode failed: {e}"))?;

    let nonce_raw = STANDARD
        .decode(nonce_b64)
        .map_err(|e| format!("nonce base64 decode failed: {e}"))?;

    if nonce_raw.len() != 12 {
        return Err("nonce must decode to 12 bytes for AES-GCM".to_string());
    }

    let nonce = Nonce::from_slice(&nonce_raw);
    let plaintext_bytes = cipher
        .decrypt(nonce, ciphertext.as_ref())
        .map_err(|e| format!("decryption failed: {e}"))?;

    String::from_utf8(plaintext_bytes).map_err(|e| format!("utf8 decode failed: {e}"))
}
