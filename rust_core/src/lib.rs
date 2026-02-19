use std::ffi::CString;
// Removed unused SystemTime and UNIX_EPOCH
use bip39::Mnemonic;
use rand::Rng;
use sha2::{Sha256, Digest};
use ripemd::Ripemd160;
use k256::elliptic_curve::sec1::ToEncodedPoint;
use k256::SecretKey;
// Removed unused signature::Signer
use k256::ecdsa::SigningKey;
use serde::Deserialize;
use bip32::XPrv;
// Removed hex import as it's not currently used in this mock step

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
        let phrase = std::ffi::CStr::from_ptr(mnemonic_ptr).to_str().unwrap_or("");
        let mnemonic = match Mnemonic::parse(phrase) { Ok(m) => m, Err(_) => return CString::new("Invalid Mnemonic").unwrap().into_raw() };
        
        let seed = mnemonic.to_seed("");
        let root_xprv = XPrv::new(&seed).expect("Failed to create root key");
        let child_xprv = root_xprv.derive_path("m/44'/4'/0'/0/0").expect("Path derivation failed");
        
        let public_key = child_xprv.public_key();
        let pubkey_bytes = public_key.to_bytes();
        
        let mut sha256_hasher = Sha256::new(); sha256_hasher.update(&pubkey_bytes);
        let mut ripemd_hasher = Ripemd160::new(); ripemd_hasher.update(&sha256_hasher.finalize());
        let mut payload = vec![0x3D]; payload.extend_from_slice(&ripemd_hasher.finalize());
        let address = bs58::encode(payload).with_check().into_string();
        CString::new(address).unwrap().into_raw()
    }
}

// Temporary Comment out unused structs/functions to appease the linter until we inject the real signer
// pub struct ByteWriter { pub buffer: Vec<u8> }
// fn decode_address_to_pkh...
// fn build_p2pkh_script...
// fn build_op_return_script...

#[derive(Deserialize, Debug)]
pub struct Utxo { pub txid: String, pub vout: u32, pub value: u64 }

#[derive(Deserialize, Debug)]
pub struct TransactionRequest {
    pub mnemonic: String, 
    pub destination_address: String, 
    pub amount_sats: u64,
    pub change_address: String, 
    pub fee_sats: u64, 
    pub utxos: Vec<Utxo>, 
    pub op_return_data: Option<String>
}

#[no_mangle]
pub extern "C" fn build_and_sign_tx_ffi(json_request_ptr: *const std::os::raw::c_char) -> *mut std::os::raw::c_char {
    unsafe {
        if json_request_ptr.is_null() { return std::ptr::null_mut(); }
        let json_str = std::ffi::CStr::from_ptr(json_request_ptr).to_str().unwrap_or("");
        let request: TransactionRequest = match serde_json::from_str(json_str) {
            Ok(req) => req, Err(e) => return CString::new(format!("JSON Error: {}", e)).unwrap().into_raw(),
        };

        let mnemonic = match Mnemonic::parse(&request.mnemonic) {
            Ok(m) => m, Err(_) => return CString::new("Error: Invalid Mnemonic").unwrap().into_raw(),
        };
        let seed = mnemonic.to_seed("");
        let root_xprv = match XPrv::new(&seed) {
            Ok(k) => k, Err(_) => return CString::new("Error: Root key derivation failed").unwrap().into_raw(),
        };
        let child_xprv = match root_xprv.derive_path("m/44'/4'/0'/0/0") {
            Ok(k) => k, Err(_) => return CString::new("Error: Path derivation failed").unwrap().into_raw(),
        };
        
        let _signing_key = SigningKey::from_bytes(&child_xprv.private_key().to_bytes())
            .expect("Invalid signing key bytes");
        
        let mock_signed_hex = format!("SIGNED_SECURELY: [Will apply k256 signature to {} UTXOs using key derived from mnemonic]", request.utxos.len());
        CString::new(mock_signed_hex).unwrap().into_raw()
    }
}

#[no_mangle]
pub extern "C" fn rust_cstr_free(s: *mut std::os::raw::c_char) {
    unsafe { if !s.is_null() { let _ = CString::from_raw(s); } };
}
