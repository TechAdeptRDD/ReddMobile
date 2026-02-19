# 🔴 ReddMobile: The Decentralized Social Wallet

ReddMobile is a next-generation, non-custodial cryptocurrency wallet built for the Reddcoin (RDD) network. It bridges institutional-grade Rust cryptography with a hyper-social, gamified Flutter frontend, creating the ultimate Web3 tipping ecosystem for "ReddHeads."

## ✨ Core Features
* **Offline Rust Cryptography:** ECDSA transaction forging, BIP39 seed generation, and BIP44 derivation are executed entirely in a memory-safe `librust_core.so` FFI sandbox.
* **Biometric Vault:** Hardware-backed `flutter_secure_storage` protected by mandatory FaceID/Fingerprint OS-level locks.
* **ReddID Ecosystem:** Decentralized identity protocol utilizing `OP_RETURN` payloads to link human-readable `@usernames` and IPFS avatars directly to the blockchain.
* **Gamified Social Tipping:**
  * **Smart Tips:** Context-aware preset buttons (☕ Coffee, 🍕 Pizza) with tactile haptic feedback.
  * **Velocity Leaderboard:** Real-time tracking of the network's most active tippers (PoSV gamification).
  * **On-Chain Memos:** Attach public messages to your tips, readable in the Global Activity Feed.
* **Redundant Network Architecture:** Intelligent Blockbook node routing with in-memory caching to guarantee maximum uptime, speed, and API protection.
* **VIP Exportable ReddCards:** Generate beautiful, high-res receive cards to share directly to Web2 social media.

## 🚀 Getting Started
Please see `CONTRIBUTING.md` for instructions on how to set up the Rust compilation targets before running the Flutter application.

---
*Built by the community, for the future of decentralized social finance.*
