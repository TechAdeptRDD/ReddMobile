mod transaction_builder;
mod transaction_signer;
mod vault_crypto;

use std::ffi::{CStr, CString};
use std::os::raw::c_char;

fn c_str_arg<'a>(ptr: *const c_char, field_name: &str) -> Result<&'a str, String> {
    if ptr.is_null() {
        return Err(format!("{field_name} pointer is null"));
    }

    let c_str = unsafe { CStr::from_ptr(ptr) };
    c_str
        .to_str()
        .map_err(|e| format!("{field_name} is not valid UTF-8: {e}"))
}

fn parse_key_hex(key_hex_ptr: *const c_char) -> Result<[u8; 32], String> {
    let key_hex = c_str_arg(key_hex_ptr, "key_hex")?;

    if key_hex.len() != 64 {
        return Err("key_hex must be exactly 64 hex characters (32 bytes)".to_string());
    }

    let mut key = [0u8; 32];
    hex::decode_to_slice(key_hex, &mut key)
        .map_err(|e| format!("key_hex decode failed (expected valid 64-char hex): {e}"))?;

    Ok(key)
}

fn to_ffi_string(result: Result<String, String>) -> *mut c_char {
    let payload = match result {
        Ok(value) => format!("OK:{value}"),
        Err(err) => format!("ERR:{err}"),
    };

    match CString::new(payload) {
        Ok(c_string) => c_string.into_raw(),
        Err(_) => CString::new("ERR:failed to create ffi string")
            .expect("static fallback is valid")
            .into_raw(),
    }
}

fn pack_ciphertext_nonce(ciphertext_b64: String, nonce_b64: String) -> String {
    format!("{ciphertext_b64}:{nonce_b64}")
}

fn unpack_ciphertext_nonce(packed_b64: &str) -> Result<(&str, &str), String> {
    let (ciphertext_b64, nonce_b64) = packed_b64
        .split_once(':')
        .ok_or_else(|| "packed_b64 must be in `<ciphertext_b64>:<nonce_b64>` format".to_string())?;

    if ciphertext_b64.is_empty() || nonce_b64.is_empty() {
        return Err("packed_b64 has empty ciphertext or nonce segment".to_string());
    }

    Ok((ciphertext_b64, nonce_b64))
}

/// Encrypts plaintext using AES-256-GCM.
/// Input key must be a 64-char hex string encoding 32 raw bytes.
/// Returns: `OK:<packed_base64>` or `ERR:<message>`.
#[unsafe(no_mangle)]
pub extern "C" fn vault_encrypt(plaintext: *const c_char, key_hex: *const c_char) -> *mut c_char {
    let result = (|| {
        let plaintext = c_str_arg(plaintext, "plaintext")?;
        let mut key = parse_key_hex(key_hex)?;

        vault_crypto::encrypt(plaintext, &mut key)
            .map(|(ciphertext_b64, nonce_b64)| pack_ciphertext_nonce(ciphertext_b64, nonce_b64))
    })();

    to_ffi_string(result)
}

/// Decrypts AES-256-GCM packed payload.
/// Input key must be a 64-char hex string encoding 32 raw bytes.
/// Returns: `OK:<plaintext>` or `ERR:<message>`.
#[unsafe(no_mangle)]
pub extern "C" fn vault_decrypt(packed_b64: *const c_char, key_hex: *const c_char) -> *mut c_char {
    let result = (|| {
        let packed_b64 = c_str_arg(packed_b64, "packed_b64")?;
        let mut key = parse_key_hex(key_hex)?;
        let (ciphertext_b64, nonce_b64) = unpack_ciphertext_nonce(packed_b64)?;

        vault_crypto::decrypt(ciphertext_b64, nonce_b64, &mut key)
    })();

    to_ffi_string(result)
}


/// Generates a hex-encoded ReddID OP_RETURN payload for FFI callers.
///
/// # Safety
/// * `command` and `identifier` must each be valid, non-null pointers to NUL-terminated strings.
/// * The returned pointer owns heap-allocated memory from Rust (`CString::into_raw`).
/// * The caller is responsible for freeing the returned pointer with `vault_string_free` when done.
/// * The returned string is prefixed as `OK:<hex_payload>` on success or `ERR:<message>` on error.
#[unsafe(no_mangle)]
pub extern "C" fn generate_reddid_payload_ffi(
    command: *const c_char,
    identifier: *const c_char,
) -> *mut c_char {
    let result = (|| {
        // Convert input C strings into validated UTF-8 Rust-owned strings so we can safely pass
        // them deeper into Rust logic without depending on caller-managed lifetimes.
        let command = c_str_arg(command, "command")?.to_string();
        let identifier = c_str_arg(identifier, "identifier")?.to_string();

        transaction_builder::build_opreturn_payload(command, identifier)
    })();

    to_ffi_string(result)
}


/// Signs a Reddcoin-style OP_RETURN transaction and returns a raw transaction hex string.
///
/// # Safety
/// * All `*const c_char` inputs must be non-null pointers to valid NUL-terminated UTF-8 strings.
/// * The returned pointer is allocated by Rust via `CString::into_raw` and must be released by
///   the caller by invoking `vault_string_free` exactly once.
/// * The caller must not mutate or free the returned pointer using non-Rust allocators.
/// * Return payload format is `OK:<raw_tx_hex>` on success and `ERR:<message>` on failure.
#[unsafe(no_mangle)]
pub extern "C" fn sign_opreturn_transaction_ffi(
    private_key_hex: *const c_char,
    utxo_txid: *const c_char,
    utxo_vout: u32,
    utxo_amount: u64,
    op_return_payload: *const c_char,
    change_address: *const c_char,
    network_fee: u64,
) -> *mut c_char {
    let result = (|| {
        // Convert incoming C pointers into validated UTF-8 Rust-owned values before dispatching
        // into the signer module. This isolates unsafety at the FFI edge.
        let private_key_hex = c_str_arg(private_key_hex, "private_key_hex")?.to_string();
        let utxo_txid = c_str_arg(utxo_txid, "utxo_txid")?.to_string();
        let op_return_payload = c_str_arg(op_return_payload, "op_return_payload")?.to_string();
        let change_address = c_str_arg(change_address, "change_address")?.to_string();

        transaction_signer::sign_opreturn_transaction(
            private_key_hex,
            utxo_txid,
            utxo_vout,
            utxo_amount,
            op_return_payload,
            change_address,
            network_fee,
        )
    })();

    to_ffi_string(result)
}

/// Frees strings allocated by this library.
#[unsafe(no_mangle)]
pub extern "C" fn vault_string_free(ptr: *mut c_char) {
    if ptr.is_null() {
        return;
    }

    unsafe {
        let _ = CString::from_raw(ptr);
    }
}
