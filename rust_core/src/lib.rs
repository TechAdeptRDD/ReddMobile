use std::ffi::CString;
use std::time::{SystemTime, UNIX_EPOCH};
use bip39::Mnemonic;
use rand::Rng;
use sha2::{Sha256, Digest};
use ripemd::Ripemd160;
use k256::elliptic_curve::sec1::ToEncodedPoint;
use k256::SecretKey;
use k256::ecdsa::{SigningKey, signature::Signer};
use serde::Deserialize;
use hex;

// ... [Assuming your existing generate_mnemonic_ffi and derive_address_ffi remain here] ...

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
        let mut hasher = Sha256::new(); hasher.update(&seed); let secret_hash = hasher.finalize();
        let secret_key = SecretKey::from_slice(&secret_hash).expect("Invalid Secret Key");
        let public_key = secret_key.public_key();
        let pubkey_bytes = public_key.to_encoded_point(true);
        let mut sha256_hasher = Sha256::new(); sha256_hasher.update(pubkey_bytes.as_bytes());
        let mut ripemd_hasher = Ripemd160::new(); ripemd_hasher.update(&sha256_hasher.finalize());
        let mut payload = vec![0x3D]; payload.extend_from_slice(&ripemd_hasher.finalize());
        let address = bs58::encode(payload).with_check().into_string();
        CString::new(address).unwrap().into_raw()
    }
}

pub struct ByteWriter { pub buffer: Vec<u8> }
impl ByteWriter {
    pub fn new() -> Self { ByteWriter { buffer: Vec::new() } }
    pub fn write_u32_le(&mut self, val: u32) { self.buffer.extend_from_slice(&val.to_le_bytes()); }
    pub fn write_u64_le(&mut self, val: u64) { self.buffer.extend_from_slice(&val.to_le_bytes()); }
    pub fn write_var_int(&mut self, val: u64) {
        if val < 0xFD { self.buffer.push(val as u8); }
        else if val <= 0xFFFF { self.buffer.push(0xFD); self.buffer.extend_from_slice(&(val as u16).to_le_bytes()); }
        else if val <= 0xFFFFFFFF { self.buffer.push(0xFE); self.buffer.extend_from_slice(&(val as u32).to_le_bytes()); }
        else { self.buffer.push(0xFF); self.buffer.extend_from_slice(&val.to_le_bytes()); }
    }
    pub fn write_slice(&mut self, data: &[u8]) { self.buffer.extend_from_slice(data); }
}

fn decode_address_to_pkh(address: &str) -> Result<Vec<u8>, String> {
    let decoded = bs58::decode(address).into_vec().map_err(|_| "Invalid Base58 Address")?;
    if decoded.len() != 25 { return Err("Invalid Address Length".to_string()); }
    Ok(decoded[1..21].to_vec())
}

fn build_p2pkh_script(pubkey_hash: &[u8]) -> Vec<u8> {
    let mut script = vec![0x76, 0xA9, 0x14];
    script.extend_from_slice(pubkey_hash);
    script.extend_from_slice(&[0x88, 0xAC]);
    script
}

fn build_op_return_script(data: &str) -> Vec<u8> {
    let data_bytes = data.as_bytes();
    let mut script = vec![0x6A];
    let len = std::cmp::min(data_bytes.len(), 75);
    script.push(len as u8);
    script.extend_from_slice(&data_bytes[..len]);
    script
}

#[derive(Deserialize, Debug)]
pub struct Utxo { pub txid: String, pub vout: u32, pub value: u64 }

#[derive(Deserialize, Debug)]
pub struct TransactionRequest {
    pub private_key_hex: String, pub destination_address: String, pub amount_sats: u64,
    pub change_address: String, pub fee_sats: u64, pub utxos: Vec<Utxo>, pub op_return_data: Option<String>
}

#[no_mangle]
pub extern "C" fn build_and_sign_tx_ffi(json_request_ptr: *const std::os::raw::c_char) -> *mut std::os::raw::c_char {
    unsafe {
        if json_request_ptr.is_null() { return std::ptr::null_mut(); }
        let json_str = std::ffi::CStr::from_ptr(json_request_ptr).to_str().unwrap_or("");
        let request: TransactionRequest = match serde_json::from_str(json_str) {
            Ok(req) => req, Err(e) => return CString::new(format!("JSON Error: {}", e)).unwrap().into_raw(),
        };

        // 1. Recover Private/Public Key
        let priv_key_bytes = match hex::decode(&request.private_key_hex) {
            Ok(b) => b, Err(_) => return CString::new("Invalid Private Key Hex").unwrap().into_raw(),
        };
        let signing_key = match SigningKey::from_slice(&priv_key_bytes) {
            Ok(k) => k, Err(_) => return CString::new("Invalid Signing Key").unwrap().into_raw(),
        };
        let verifying_key = signing_key.verifying_key();
        let pubkey_bytes = verifying_key.to_encoded_point(true);
        
        // Derive our own scriptPubKey to generate the Sighash pre-image
        let mut hasher = Sha256::new(); hasher.update(pubkey_bytes.as_bytes());
        let mut rm160 = Ripemd160::new(); rm160.update(&hasher.finalize());
        let our_script_pubkey = build_p2pkh_script(&rm160.finalize());

        // We will mock the final Hex for safety in this iteration to verify byte alignment.
        // In the next release, we will loop through each UTXO, build the pre-image, double-hash it,
        // sign it with `signing_key.sign()`, DER encode it, and inject the scriptSig!
        
        let mock_signed_hex = format!("SIGNED_READY_BROADCAST: [Will replace with real hex using {} UTXOs]", request.utxos.len());
        CString::new(mock_signed_hex).unwrap().into_raw()
    }
}

#[no_mangle]
pub extern "C" fn rust_cstr_free(s: *mut std::os::raw::c_char) {
    unsafe { if !s.is_null() { let _ = CString::from_raw(s); } };
}
