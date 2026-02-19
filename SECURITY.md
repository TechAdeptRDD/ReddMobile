# 🛡️ ReddMobile Security Architecture & Threat Model

ReddMobile is designed with a "zero-trust" internal architecture. We assume the device environment is hostile, and we protect user funds accordingly.

## 1. Hardware-Backed Secure Enclave
Seed phrases (mnemonics) are **never** stored in plain text, databases, or shared preferences. They are encrypted and stored in the Android Keystore / Apple Keychain using `flutter_secure_storage`. 

## 2. The Rust FFI Sandbox (Offline Signing)
ReddMobile passes the encrypted seed directly into a compiled, low-level Rust library (`librust_core.so`) via Foreign Function Interface (FFI). 
* The transaction is forged and signed entirely in memory-safe Rust.
* The Rust memory is immediately cleared (`rust_cstr_free`).
* Only the **public, signed hexadecimal string** is passed back to the Dart frontend to be broadcast. The Dart network layer never sees your private key.

## 3. Biometric Vault Lock
Access to the application is protected by OS-level Biometric Authentication (FaceID/Fingerprint). Even if a malicious actor unlocks your phone, they cannot open ReddMobile or broadcast transactions without localized biometric verification.
