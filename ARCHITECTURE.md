# 🏗️ ReddMobile Systems Architecture

## 1. The Rust FFI Layer
Instead of relying on slow or unmaintained Dart cryptographic libraries, ReddMobile uses a custom Rust engine (`rust_core`).
* **Memory Safety:** Strings passed between Dart and C/Rust are explicitly allocated and freed using `rust_cstr_free` to prevent memory leaks.
* **Offline Signing:** The `build_and_sign_tx_ffi` function constructs the raw hexadecimal transaction, signs inputs using ECDSA (`k256`), and returns a broadcast-ready payload without ever exposing the private key to the network layer.

## 2. The ReddID Protocol (OP_RETURN)
When a user claims a ReddID, the wallet constructs a standard transaction sending a tiny amount of RDD to themselves. It attaches an `OP_RETURN` script containing:
`RDD:ID:<username>:<ipfs_cid>`
* The UI parses this payload from the blockchain history to resolve usernames to addresses globally.

## 3. State Management (BLoC)
The app utilizes the BLoC (Business Logic Component) pattern to separate UI from network calls. 
* `ActivityBloc`: Polls the Blockbook indexer for global network registrations.
* `DashboardBloc`: Manages local wallet state, UTXO fetching, and balance calculations.
