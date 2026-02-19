use std::ffi::CString;
use std::time::{SystemTime, UNIX_EPOCH};
use bip39::Mnemonic;
use rand::Rng;
use sha2::{Sha256, Digest};
use ripemd::Ripemd160;
use k256::elliptic_curve::sec1::ToEncodedPoint;
use k256::SecretKey;
use serde::Deserialize;
use hex;

// --- EXISTING WORKING MNEMONIC & ADDRESS DERIVATION --- //

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

// --- NEW: REDDCOIN BYTE WRITER & SERIALIZATION ENGINE --- //

pub struct ByteWriter {
    pub buffer: Vec<u8>,
}

impl ByteWriter {
    pub fn new() -> Self {
        ByteWriter { buffer: Vec::new() }
    }

    pub fn write_u32_le(&mut self, val: u32) {
        self.buffer.extend_from_slice(&val.to_le_bytes());
    }

    pub fn write_u64_le(&mut self, val: u64) {
        self.buffer.extend_from_slice(&val.to_le_bytes());
    }

    pub fn write_var_int(&mut self, val: u64) {
        if val < 0xFD {
            self.buffer.push(val as u8);
        } else if val <= 0xFFFF {
            self.buffer.push(0xFD);
            self.buffer.extend_from_slice(&(val as u16).to_le_bytes());
        } else if val <= 0xFFFFFFFF {
            self.buffer.push(0xFE);
            self.buffer.extend_from_slice(&(val as u32).to_le_bytes());
        } else {
            self.buffer.push(0xFF);
            self.buffer.extend_from_slice(&val.to_le_bytes());
        }
    }

    pub fn write_slice(&mut self, data: &[u8]) {
        self.buffer.extend_from_slice(data);
    }
}

// Decodes a Base58Check address into its 20-byte PubKeyHash
fn decode_address_to_pkh(address: &str) -> Result<Vec<u8>, String> {
    let decoded = bs58::decode(address).into_vec().map_err(|_| "Invalid Base58 Address")?;
    if decoded.len() != 25 { return Err("Invalid Address Length".to_string()); }
    // Drop the 1-byte version prefix (0x3D) and the 4-byte checksum suffix
    Ok(decoded[1..21].to_vec())
}

// Builds: OP_DUP OP_HASH160 <20-byte-Hash> OP_EQUALVERIFY OP_CHECKSIG
fn build_p2pkh_script(pubkey_hash: &[u8]) -> Vec<u8> {
    let mut script = Vec::new();
    script.push(0x76);
    script.push(0xA9);
    script.push(0x14); // Push 20 bytes
    script.extend_from_slice(pubkey_hash);
    script.push(0x88);
    script.push(0xAC);
    script
}

// Builds the Microcredential/Social Identity Anchor
fn build_op_return_script(data: &str) -> Vec<u8> {
    let data_bytes = data.as_bytes();
    let mut script = Vec::new();
    script.push(0x6A); // OP_RETURN
    // For simplicity in this engine, we handle up to 75 bytes of data
    let len = std::cmp::min(data_bytes.len(), 75);
    script.push(len as u8); // Push data length
    script.extend_from_slice(&data_bytes[..len]);
    script
}

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
    pub op_return_data: Option<String>, // Safely captures the IPFS/Social Anchor
}

#[no_mangle]
pub extern "C" fn build_and_sign_tx_ffi(json_request_ptr: *const std::os::raw::c_char) -> *mut std::os::raw::c_char {
    unsafe {
        if json_request_ptr.is_null() { return std::ptr::null_mut(); }
        let c_str = std::ffi::CStr::from_ptr(json_request_ptr);
        let json_str = c_str.to_str().unwrap_or("");

        let request: TransactionRequest = match serde_json::from_str(json_str) {
            Ok(req) => req,
            Err(e) => return CString::new(format!("JSON Error: {}", e)).unwrap().into_raw(),
        };

        let mut tx = ByteWriter::new();

        // 1. Version (Version 2)
        tx.write_u32_le(2);

        // 2. Reddcoin nTime (Current Unix Timestamp)
        let current_time = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs() as u32;
        tx.write_u32_le(current_time);

        // 3. Inputs (UTXOs)
        tx.write_var_int(request.utxos.len() as u64);
        for utxo in &request.utxos {
            let mut txid_bytes = match hex::decode(&utxo.txid) {
                Ok(b) => b,
                Err(_) => return CString::new("Error: Invalid TXID Hex").unwrap().into_raw(),
            };
            txid_bytes.reverse(); // Internal byte order is reversed
            tx.write_slice(&txid_bytes);
            tx.write_u32_le(utxo.vout);
            
            // For now, write empty scriptSig (0x00) - Signing comes in the next phase!
            tx.write_var_int(0); 
            
            tx.write_u32_le(0xFFFFFFFF); // Sequence (RBF Disabled)
        }

        // 4. Outputs Calculation
        let mut total_input = 0;
        for utxo in &request.utxos { total_input += utxo.value; }
        
        let target_output = request.amount_sats;
        let change_output = total_input.saturating_sub(target_output + request.fee_sats);
        
        let has_op_return = request.op_return_data.is_some() && !request.op_return_data.as_ref().unwrap().is_empty();
        
        // Count outputs (1 for destination, +1 if change exists, +1 if op_return exists)
        let mut output_count = 1;
        if change_output > 0 { output_count += 1; }
        if has_op_return { output_count += 1; }
        tx.write_var_int(output_count);

        // Destination Output
        let dest_pkh = match decode_address_to_pkh(&request.destination_address) {
            Ok(pkh) => pkh,
            Err(e) => return CString::new(format!("Address Error: {}", e)).unwrap().into_raw(),
        };
        let dest_script = build_p2pkh_script(&dest_pkh);
        tx.write_u64_le(target_output);
        tx.write_var_int(dest_script.len() as u64);
        tx.write_slice(&dest_script);

        // Change Output
        if change_output > 0 {
            let change_pkh = match decode_address_to_pkh(&request.change_address) {
                Ok(pkh) => pkh,
                Err(e) => return CString::new(format!("Change Address Error: {}", e)).unwrap().into_raw(),
            };
            let change_script = build_p2pkh_script(&change_pkh);
            tx.write_u64_le(change_output);
            tx.write_var_int(change_script.len() as u64);
            tx.write_slice(&change_script);
        }

        // OP_RETURN Output (Social Identity Anchor)
        if let Some(op_data) = request.op_return_data {
            if !op_data.is_empty() {
                let op_script = build_op_return_script(&op_data);
                tx.write_u64_le(0); // OP_RETURN outputs carry 0 value
                tx.write_var_int(op_script.len() as u64);
                tx.write_slice(&op_script);
            }
        }

        // 5. LockTime
        tx.write_u32_le(0);

        // Convert the raw bytes to Hex for Flutter!
        let raw_unsigned_hex = hex::encode(tx.buffer);
        let response_payload = format!("UNSIGNED_HEX:{}", raw_unsigned_hex);

        CString::new(response_payload).unwrap().into_raw()
    }
}

#[no_mangle]
pub extern "C" fn rust_cstr_free(s: *mut std::os::raw::c_char) {
    unsafe {
        if s.is_null() { return }
        let _ = CString::from_raw(s);
    };
}
