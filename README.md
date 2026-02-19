# ReddMobile: The Next-Gen Social Wallet 📱🚀

ReddMobile is a high-performance, security-first wallet designed specifically for the **Reddcoin (RDD)** ecosystem. By combining the agility of **Flutter** with the memory safety of **Rust**, we have created a "Hybrid Engine" capable of handling complex blockchain operations with native speed.

## 🧬 The Core Philosophy
Traditional mobile wallets often struggle with speed or security tradeoffs. ReddMobile solves this via:
* **The Vault (Rust):** All private keys, ECDSA signing (secp256k1), and sensitive data management occur in a compiled Rust binary.
* **The Experience (Flutter):** A modern, reactive UI that provides instant feedback and "Glassmorphism" aesthetics.
* **The Bridge (FFI):** A low-latency interface that allows Dart to call Rust functions directly without the overhead of a standard API.

## 🗺️ Feature Roadmap
- [x] **v0.1.0:** Core Signer & Activity Feed UI.
- [x] **v0.1.3:** CI/CD "Release Factory" & Navigation Logic.
- [ ] **v0.2.0:** BIP39 Mnemonic Seed Phrases (Rust-native).
- [ ] **v0.3.0:** Biometric (FaceID/Fingerprint) Vault Unlock.
- [ ] **v1.0.0:** Mainnet Release & ReddID Marketplace.

## 🛠️ Tech Stack
* **Frontend:** Flutter 3.x (BLoC Pattern)
* **Security Core:** Rust 2021 Edition
* **API:** Blockbook (Reddcoin Implementation)
* **CI/CD:** GitHub Actions (Automated Android Builds)
