use jni::JNIEnv;
use jni::objects::{JClass}; // Removed unused JString
use jni::sys::jstring;
use std::ffi::{CString}; // Removed unused CStr
use bip39::{Mnemonic, Language};
use rand::Rng; // Import the random number generator trait

// Android JNI Bridge for "generate_wallet"
#[no_mangle]
pub extern "system" fn Java_com_reddcoin_redd_1mobile_MainActivity_generateWallet(
    env: JNIEnv,
    _class: JClass,
) -> jstring {
    // 1. Generate 128 bits (16 bytes) of cryptographically secure entropy
    let mut rng = rand::thread_rng();
    let mut entropy = [0u8; 16];
    rng.fill(&mut entropy);

    // 2. Create the Mnemonic from that entropy (English is default)
    // 128 bits of entropy = 12 words
    let mnemonic = Mnemonic::from_entropy(&entropy).expect("Failed to generate mnemonic");
    let phrase = mnemonic.word_iter().fold(String::new(), |acc, word| {
        if acc.is_empty() {
            word.to_string()
        } else {
            format!("{} {}", acc, word)
        }
    });

    // 3. Return to Java/Kotlin wrapper
    let output = env.new_string(phrase).expect("Couldn't create java string!");
    output.into_raw()
}

// C-Compatible FFI for Flutter (The direct bridge)
#[no_mangle]
pub extern "C" fn generate_mnemonic_ffi() -> *mut std::os::raw::c_char {
    // 1. Generate 128 bits (16 bytes) of entropy
    let mut rng = rand::thread_rng();
    let mut entropy = [0u8; 16];
    rng.fill(&mut entropy);

    // 2. Derive the 12-word phrase
    let mnemonic = Mnemonic::from_entropy(&entropy).expect("Failed to generate mnemonic");
    
    // bip39 v2.0 doesn't have a direct .phrase() returning String, so we reconstruct it
    // or use the display implementation.
    // However, explicit iteration is safer for FFI strings.
    let phrase_string = mnemonic.word_iter().collect::<Vec<&str>>().join(" ");
    
    let c_str = CString::new(phrase_string).unwrap();
    c_str.into_raw()
}

// Keep the freeing function to prevent memory leaks
#[no_mangle]
pub extern "C" fn rust_cstr_free(s: *mut std::os::raw::c_char) {
    unsafe {
        if s.is_null() { return }
        let _ = CString::from_raw(s);
    };
}
