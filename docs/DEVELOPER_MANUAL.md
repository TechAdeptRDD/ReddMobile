# ReddMobile: Developer & Architecture Manual

## 🏗️ The Hybrid Architecture
ReddMobile uses a **High-Performance Bridge** architecture:
1. **Frontend (Flutter/Dart):** Handles the UI, BLoC state management, and API calls to Blockbook.
2. **Core (Rust):** Handles all cryptographic operations, transaction signing, and sensitive data management.
3. **Bridge (FFI):** Uses Dart's `Foreign Function Interface` to pass data to Rust with near-zero latency.

## 📁 Repository Structure
* `/flutter_app`: The cross-platform mobile UI.
* `/rust_core`: The backend signing engine (compiled to `.so` or `.a` files).
* `/rust_core/src/transaction_signer.rs`: The heart of the wallet—handles P2PKH and OP_RETURN logic.

## 🛠️ Development Workflow

### Adding New Rust Capabilities
1. Modify logic in `rust_core/src/transaction_signer.rs`.
2. Expose the function via FFI in `rust_core/src/lib.rs` using `#[no_mangle] extern "C"`.
3. Rebuild the library: `cargo build --release`.
4. Update `lib/services/vault_crypto_service.dart` to link the new function.

### Running Tests
* **Dart Tests:** `flutter test`
* **Rust Tests:** `cargo test` (run within `/rust_core`)

## 📋 Technical Debt & Roadmap
* **Base58 Validation:** Currently uses `assume_checked()` to bypass Reddcoin's unique version byte (0x3D). This needs a formal network constant implementation in the Rust `bitcoin` crate.
* **Mnemonic Logic:** BIP39 seed phrase generation needs to be moved from Mock to Rust production logic.
