# 🗺️ ReddMobile Development Roadmap

## Phase 1: Core Cryptography & Foundation (Complete)
- [x] Rust-based ECDSA transaction signing (`rust_core`).
- [x] Secure storage for Mnemonic Seed Phrases.
- [x] ReddID OP_RETURN broadcasting & IPFS Avatar linking.
- [x] UI/UX Dashboard, Global Activity Feed, and BLoC State Management.

## Phase 2: Enhanced Social Connectivity (In Progress)
- [x] **In-Feed Tipping:** Seamlessly send RDD to users directly from the global activity feed.
- [ ] **Redd Links (Deep Linking):** Generate `redd://pay?user=@handle` URLs that open the app to a pre-filled transaction screen for sharing on Web2 platforms (X, Discord, etc.).
- [ ] **Encrypted DMs (ECIES):** Utilize the Rust cryptography engine to allow users to send encrypted messages via IPFS that only the recipient's private key can read.

## Phase 3: Network Resilience & Security
- [ ] **Fallback Indexers:** Implement an array of backup Blockbook nodes to ensure the wallet functions even if the primary Reddcoin indexer goes offline.
- [ ] **SPV (Simplified Payment Verification):** Transition from relying on centralized indexers to a Light Client model that verifies transactions directly against the P2P network.
- [ ] **Biometric Lock:** Integrate `local_auth` to require FaceID/Fingerprint when reopening the app or confirming a transaction.
