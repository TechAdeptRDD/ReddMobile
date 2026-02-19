use std::ffi::CString;
use std::time::{SystemTime, UNIX_EPOCH};
use bip39::Mnemonic;
use rand::Rng;
use sha2::{Sha256, Digest};
use ripemd::Ripemd160;
use k256::ecdsa::{SigningKey, signature::Signer, Signature};
use serde::Deserialize;
use bip32::{XPrv, ChildNumber};

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
        
        // Manual BIP44 Derivation Loop (Bypasses all string parsing errors)
        // m/44'/4'/0'/0/0 (Adding 0x80000000 creates a Hardened ' index)
        let path = [
            ChildNumber(44 + 0x80000000),
            ChildNumber(4 + 0x80000000),
            ChildNumber(0 + 0x80000000),
            ChildNumber(0),
            ChildNumber(0),
        ];
        
        let mut child_xprv = root_xprv;
        for num in path {
            child_xprv = child_xprv.derive_child(num).expect("Path derivation failed");
        }
        
        let pubkey_bytes = child_xprv.public_key().to_bytes();
        let mut sha256_hasher = Sha256::new(); sha256_hasher.update(&pubkey_bytes);
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
    pub mnemonic: String, 
    pub destination_address: String, 
    pub amount_sats: u64,
    pub change_address: String, 
    pub fee_sats: u64, 
    pub utxos: Vec<Utxo>, 
    pub op_return_data: Option<String>
}

fn serialize_tx(
    req: &TransactionRequest,
    current_time: u32,
    our_script_pubkey: &[u8],
    dest_script: &[u8],
    change_script: Option<&[u8]>,
    op_return_script: Option<&[u8]>,
    target_output: u64,
    change_output: u64,
    signing_input_index: Option<usize>,
    script_sigs: &[Vec<u8>]
) -> Result<Vec<u8>, String> {
    let mut tx = ByteWriter::new();
    tx.write_u32_le(2); 
    tx.write_u32_le(current_time);

    tx.write_var_int(req.utxos.len() as u64);
    for (i, utxo) in req.utxos.iter().enumerate() {
        let mut txid_bytes = hex::decode(&utxo.txid).map_err(|_| "Invalid TXID Hex")?;
        txid_bytes.reverse();
        tx.write_slice(&txid_bytes);
        tx.write_u32_le(utxo.vout);

        if let Some(sign_idx) = signing_input_index {
            if i == sign_idx {
                tx.write_var_int(our_script_pubkey.len() as u64);
                tx.write_slice(our_script_pubkey);
            } else {
                tx.write_var_int(0); 
            }
        } else {
            let sig_script = &script_sigs[i];
            tx.write_var_int(sig_script.len() as u64);
            tx.write_slice(sig_script);
        }
        tx.write_u32_le(0xFFFFFFFF);
    }

    let mut output_count = 1;
    if change_output > 0 { output_count += 1; }
    if op_return_script.is_some() { output_count += 1; }
    tx.write_var_int(output_count);

    tx.write_u64_le(target_output);
    tx.write_var_int(dest_script.len() as u64);
    tx.write_slice(dest_script);

    if let Some(c_script) = change_script {
        tx.write_u64_le(change_output);
        tx.write_var_int(c_script.len() as u64);
        tx.write_slice(c_script);
    }

    if let Some(op_script) = op_return_script {
        tx.write_u64_le(0);
        tx.write_var_int(op_script.len() as u64);
        tx.write_slice(op_script);
    }

    tx.write_u32_le(0); 
    if signing_input_index.is_some() { tx.write_u32_le(1); } // SIGHASH_ALL

    Ok(tx.buffer)
}

#[no_mangle]
pub extern "C" fn build_and_sign_tx_ffi(json_request_ptr: *const std::os::raw::c_char) -> *mut std::os::raw::c_char {
    unsafe {
        if json_request_ptr.is_null() { return std::ptr::null_mut(); }
        let json_str = std::ffi::CStr::from_ptr(json_request_ptr).to_str().unwrap_or("");
        let request: TransactionRequest = match serde_json::from_str(json_str) {
            Ok(req) => req, Err(e) => return CString::new(format!("JSON Error: {}", e)).unwrap().into_raw(),
        };

        let mnemonic = match Mnemonic::parse(&request.mnemonic) { Ok(m) => m, Err(_) => return CString::new("Error: Invalid Mnemonic").unwrap().into_raw() };
        let seed = mnemonic.to_seed("");
        let root_xprv = match XPrv::new(&seed) { Ok(k) => k, Err(_) => return CString::new("Error: Root key failed").unwrap().into_raw() };
        
        let path = [
            ChildNumber(44 + 0x80000000),
            ChildNumber(4 + 0x80000000),
            ChildNumber(0 + 0x80000000),
            ChildNumber(0),
            ChildNumber(0),
        ];
        
        let mut child_xprv = root_xprv;
        for num in path {
            child_xprv = match child_xprv.derive_child(num) {
                Ok(k) => k, Err(_) => return CString::new("Error: Path failed").unwrap().into_raw()
            };
        }
        
        let signing_key = SigningKey::from_bytes(&child_xprv.private_key().to_bytes()).expect("Invalid key");
        let pubkey_array = child_xprv.public_key().to_bytes();
        let pub_bytes = pubkey_array.as_slice();
        
        let mut hasher = Sha256::new(); hasher.update(pub_bytes);
        let mut rm160 = Ripemd160::new(); rm160.update(&hasher.finalize());
        let our_script_pubkey = build_p2pkh_script(&rm160.finalize());

        let dest_pkh = match decode_address_to_pkh(&request.destination_address) { Ok(p) => p, Err(e) => return CString::new(e).unwrap().into_raw() };
        let dest_script = build_p2pkh_script(&dest_pkh);
        
        let mut total_input = 0;
        for utxo in &request.utxos { total_input += utxo.value; }
        let change_output = total_input.saturating_sub(request.amount_sats + request.fee_sats);
        
        let mut change_script_opt = None;
        let change_script_vec: Vec<u8>;
        if change_output > 0 {
            let change_pkh = match decode_address_to_pkh(&request.change_address) { Ok(p) => p, Err(e) => return CString::new(e).unwrap().into_raw() };
            change_script_vec = build_p2pkh_script(&change_pkh);
            change_script_opt = Some(change_script_vec.as_slice());
        }

        let mut op_script_opt = None;
        let op_script_vec: Vec<u8>;
        if let Some(op_data) = &request.op_return_data {
            if !op_data.is_empty() {
                op_script_vec = build_op_return_script(op_data);
                op_script_opt = Some(op_script_vec.as_slice());
            }
        }

        let current_time = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs() as u32;

        let mut final_script_sigs: Vec<Vec<u8>> = Vec::new();
        for i in 0..request.utxos.len() {
            let pre_image = match serialize_tx(&request, current_time, &our_script_pubkey, &dest_script, change_script_opt, op_script_opt, request.amount_sats, change_output, Some(i), &[]) {
                Ok(b) => b, Err(e) => return CString::new(e).unwrap().into_raw()
            };
            
            let mut h1 = Sha256::new(); h1.update(&pre_image);
            let mut h2 = Sha256::new(); h2.update(&h1.finalize());
            let sighash = h2.finalize();

            let signature: Signature = signing_key.sign(&sighash);
            let der_bytes = signature.to_der();
            
            let mut script_sig = Vec::new();
            script_sig.push((der_bytes.len() + 1) as u8);
            script_sig.extend_from_slice(der_bytes.as_bytes());
            script_sig.push(0x01); // SIGHASH_ALL
            script_sig.push(pub_bytes.len() as u8);
            script_sig.extend_from_slice(pub_bytes);
            
            final_script_sigs.push(script_sig);
        }

        let final_tx = match serialize_tx(&request, current_time, &our_script_pubkey, &dest_script, change_script_opt, op_script_opt, request.amount_sats, change_output, None, &final_script_sigs) {
            Ok(b) => b, Err(e) => return CString::new(e).unwrap().into_raw()
        };

        let raw_hex = hex::encode(final_tx);
        CString::new(raw_hex).unwrap().into_raw()
    }
}

#[no_mangle]
pub extern "C" fn rust_cstr_free(s: *mut std::os::raw::c_char) {
    unsafe { if !s.is_null() { let _ = CString::from_raw(s); } };
}
