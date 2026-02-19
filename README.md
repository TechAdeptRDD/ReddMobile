# 🔴 ReddMobile: The Decentralized Social Wallet

ReddMobile is a next-generation, non-custodial cryptocurrency wallet built for the Reddcoin (RDD) network. It goes beyond simple value transfer by integrating **ReddID**, a decentralized identity protocol that links human-readable `@usernames` and IPFS avatars directly to the blockchain.

## ✨ Core Features
* **True Non-Custodial Security:** Private keys never leave the device. Seed phrases are stored in encrypted hardware enclaves via `flutter_secure_storage`.
* **Rust Cryptographic Engine:** ECDSA signatures, BIP32/BIP39/BIP44 derivation, and raw transaction serialization are handled entirely offline by a highly optimized, memory-safe Rust core via FFI.
* **ReddID Ecosystem:** Claim a unique `@handle`, upload an avatar to IPFS, and permanently anchor your identity to the blockchain using custom `OP_RETURN` payloads.
* **Social Resolution:** Send funds to `@usernames` instead of long cryptographic addresses. The wallet automatically queries the decentralized index to verify the recipient's identity and IPFS avatar.
* **Web3 Activity Feed:** Watch a real-time, global feed of users claiming identities and tipping each other on the network.

## 🛠️ Tech Stack
* **Frontend:** Flutter (Dart) & BLoC State Management
* **Cryptography:** Rust (compiled to Android `jniLibs` via `cargo-ndk`)
* **Decentralized Storage:** IPFS (InterPlanetary File System)
* **Blockchain Indexing:** Blockbook API

## 🚀 Getting Started
1. Clone the repository.
2. Ensure you have the Flutter SDK (3.19.0+) and Rust Toolchain installed.
3. Run `cargo ndk` in the `rust_core` directory to build the cryptographic engine.
4. Run `flutter run` in the `flutter_app` directory.

---
*Built for the future of decentralized social tipping.*
