use std::ffi::CString;
use bip39::Mnemonic;
use rand::Rng;
use sha2::{Sha256, Digest};
use ripemd::Ripemd160;
use k256::elliptic_curve::sec1::ToEncodedPoint;
use k256::SecretKey;

#[no_mangle]
pub extern "C" fn generate_mnemonic_ffi() -> *mut std::os::raw::c_char {
    let mut rng = rand::thread_rng();
    let mut entropy = [0u8; 16];
    rng.fill(&mut entropy);
    let mnemonic = Mnemonic::from_entropy(&entropy).expect("Failed to generate mnemonic");
    
    let phrase_string = mnemonic.words().collect::<Vec<&str>>().join(" ");
    CString::new(phrase_string).unwrap().into_raw()
}

#[no_mangle]
pub extern "C" fn derive_address_ffi(mnemonic_ptr: *const std::os::raw::c_char) -> *mut std::os::raw::c_char {
    unsafe {
        if mnemonic_ptr.is_null() { return std::ptr::null_mut(); }
        let c_str = std::ffi::CStr::from_ptr(mnemonic_ptr);
        let phrase = c_str.to_str().unwrap_or("");

        let mnemonic = match Mnemonic::parse(phrase) {
            Ok(m) => m,
            Err(_) => return CString::new("Invalid Mnemonic").unwrap().into_raw(),
        };

        let seed = mnemonic.to_seed("");
        let mut hasher = Sha256::new();
        hasher.update(&seed);
        let secret_hash = hasher.finalize();

        let secret_key = SecretKey::from_slice(&secret_hash).expect("Invalid Secret Key");
        let public_key = secret_key.public_key();
        let compressed_pubkey = public_key.to_encoded_point(true);
        let pubkey_bytes = compressed_pubkey.as_bytes();

        let mut sha256_hasher = Sha256::new();
        sha256_hasher.update(pubkey_bytes);
        let sha2_result = sha256_hasher.finalize();

        let mut ripemd_hasher = Ripemd160::new();
        ripemd_hasher.update(&sha2_result);
        let ripemd_result = ripemd_hasher.finalize();

        let mut payload = vec![0x3D]; 
        payload.extend_from_slice(&ripemd_result);

        let address = bs58::encode(payload).with_check().into_string();

        CString::new(address).unwrap().into_raw()
    }
}

#[no_mangle]
pub extern "C" fn rust_cstr_free(s: *mut std::os::raw::c_char) {
    unsafe {
        if s.is_null() { return }
        let _ = CString::from_raw(s);
    };
}

use serde::Deserialize;

#[derive(Deserialize, Debug)]
pub struct Utxo {
    pub txid: String,
    pub vout: u32,
    pub value: u64,
}

#[derive(Deserialize, Debug)]
pub struct TransactionRequest {
    pub private_key_hex: String,
    pub destination_address: String,
    pub amount_sats: u64,
    pub change_address: String,
    pub fee_sats: u64,
    pub utxos: Vec<Utxo>,
}

#[no_mangle]
pub extern "C" fn build_and_sign_tx_ffi(json_request_ptr: *const std::os::raw::c_char) -> *mut std::os::raw::c_char {
    unsafe {
        if json_request_ptr.is_null() { return std::ptr::null_mut(); }
        let c_str = std::ffi::CStr::from_ptr(json_request_ptr);
        let json_str = c_str.to_str().unwrap_or("");

        // Attempt to parse the Flutter JSON into Rust Structs
        let request: TransactionRequest = match serde_json::from_str(json_str) {
            Ok(req) => req,
            Err(e) => {
                let err_msg = format!("JSON Parse Error: {}", e);
                return CString::new(err_msg).unwrap().into_raw();
            }
        };

        // TODO: In the next phase, we will serialize the exact bytes and use k256 to sign.
        // For now, we return a dynamic string proving Rust successfully read the Flutter data!
        let mock_hex_response = format!(
            "MOCK_HEX_READY_FOR_BROADCAST_WITH_{}_UTXOS_TO_{}", 
            request.utxos.len(), 
            request.destination_address
        );
        
        CString::new(mock_hex_response).unwrap().into_raw()
    }
}
