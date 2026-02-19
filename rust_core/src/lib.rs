use jni::JNIEnv;
use jni::objects::{JClass, JString};
use jni::sys::jstring;
use std::ffi::{CStr, CString};
use bip39::{Mnemonic, MnemonicType, Language};

// Android JNI Bridge for "generate_wallet"
#[no_mangle]
pub extern "system" fn Java_com_reddcoin_redd_1mobile_MainActivity_generateWallet(
    env: JNIEnv,
    _class: JClass,
) -> jstring {
    // 1. Generate a secure 12-word mnemonic
    let mnemonic = Mnemonic::new(MnemonicType::Words12, Language::English);
    let phrase = mnemonic.phrase();

    // 2. (Future) Derive the Private Key & Reddcoin Address here
    // For Alpha 0.2.0, we return the phrase to prove generation works.
    
    let output = env.new_string(phrase).expect("Couldn't create java string!");
    output.into_raw()
}

// C-Compatible FFI for Flutter (The direct bridge)
#[no_mangle]
pub extern "C" fn generate_mnemonic_ffi() -> *mut std::os::raw::c_char {
    let mnemonic = Mnemonic::new(MnemonicType::Words12, Language::English);
    let phrase = mnemonic.phrase();
    
    let c_str = CString::new(phrase).unwrap();
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
