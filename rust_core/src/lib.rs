use std::ffi::CString;
use bip39::Mnemonic;
use rand::Rng;
use sha2::{Sha256, Digest};
use ripemd::Ripemd160;
use k256::elliptic_curve::sec1::ToEncodedPoint;
use k256::SecretKey;

/// Generates a 12-word phrase
#[no_mangle]
pub extern "C" fn generate_mnemonic_ffi() -> *mut std::os::raw::c_char {
    let mut rng = rand::thread_rng();
    let mut entropy = [0u8; 16];
    rng.fill(&mut entropy);
    let mnemonic = Mnemonic::from_entropy(&entropy).expect("Failed to generate mnemonic");
    
    // Updated from deprecated word_iter() to words()
    let phrase_string = mnemonic.words().collect::<Vec<&str>>().join(" ");
    CString::new(phrase_string).unwrap().into_raw()
}

/// Derives a Reddcoin Address (R...) from a 12-word phrase
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

        // SHA256 Hash the seed to get deterministic secret key entropy
        let seed = mnemonic.to_seed("");
        let mut hasher = Sha256::new();
        hasher.update(&seed);
        let secret_hash = hasher.finalize();

        // Extract Public Key
        let secret_key = SecretKey::from_slice(&secret_hash).expect("Invalid Secret Key");
        let public_key = secret_key.public_key();
        let compressed_pubkey = public_key.to_encoded_point(true);
        let pubkey_bytes = compressed_pubkey.as_bytes();

        // Double Hash for Address (SHA256 -> RIPEMD160)
        let mut sha256_hasher = Sha256::new();
        sha256_hasher.update(pubkey_bytes);
        let sha2_result = sha256_hasher.finalize();

        let mut ripemd_hasher = Ripemd160::new();
        ripemd_hasher.update(&sha2_result);
        let ripemd_result = ripemd_hasher.finalize();

        // 0x3D is the Reddcoin Mainnet Byte for 'R'
        let mut payload = vec![0x3D]; 
        payload.extend_from_slice(&ripemd_result);

        // Base58Check Encoding (now works because 'check' feature is enabled)
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
