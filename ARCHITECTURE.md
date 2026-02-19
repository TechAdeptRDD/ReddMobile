# 🏗️ ReddMobile Systems Architecture

## 1. The FFI Security Sandbox (Rust <-> Dart)
ReddMobile operates on a "zero-trust" internal model. The Dart frontend never processes private keys for network broadcasting.
* **The Bridge:** `VaultCryptoService` passes the encrypted mnemonic to Rust via FFI.
* **Execution:** `build_and_sign_tx_ffi` constructs the raw hexadecimal transaction, signs it offline, and immediately frees the memory (`rust_cstr_free`).
* **Output:** Only the broadcast-ready public hexadecimal string is returned to Dart.

## 2. Network Resilience & Indexing
The app relies on the `BlockbookService` to read the blockchain.
* **Redundancy Array:** The service maintains a list of fallback nodes. If a node times out, it seamlessly fails over to the next.
* **Anti-Spam Cache:** Global Feed data is cached in-memory for 30 seconds to prevent DDoS-ing our own infrastructure during rapid tab-switching.
* **Dynamic Fees:** The network is queried for live fee estimation prior to every transaction to prevent stuck broadcasts.

## 3. Data Storage & Migrations
* **Keystore:** Utilizes OS-level enclaves (Android Keystore / Apple Keychain).
* **Avatar-Rich Contacts:** The `SecureStorageService` maps `@handles` to IPFS CIDs. It includes a fallback migration path to seamlessly upgrade legacy text-only contacts to the new JSON format without data loss.

## 4. Web2 Identity Anchoring (V2 Infrastructure)
The settings UI includes placeholders for X/Twitter and Discord linking. Future architecture will involve generating a cryptographic signature within the app that users post to their Web2 bios, allowing a decentralized oracle to verify and anchor the cross-platform identity.
