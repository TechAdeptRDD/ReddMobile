# 🗺️ ReddMobile Development Roadmap

## Phase 1: Core Cryptography & Foundation (✅ Complete)
- [x] Rust-based ECDSA transaction signing via FFI.
- [x] Secure storage for Mnemonic Seed Phrases.
- [x] ReddID OP_RETURN broadcasting & IPFS Avatar linking.
- [x] UI/UX Dashboard and BLoC State Management.

## Phase 2: Enhanced Social Connectivity (✅ Complete)
- [x] **In-Feed Tipping & On-Chain Memos:** Tip users directly with attached messages.
- [x] **Gamification:** Velocity Leaderboard and "Redd Level" dynamic dashboard borders.
- [x] **Exportable ReddCards:** High-res shareable receive screens.
- [x] **Fiat Oracle:** Live RDD-to-USD conversion on the dashboard.
- [x] **Redd Links (Deep Linking):** OS-level `redd://pay?user=@handle` interception.

## Phase 3: Web2 Integration & Privacy (Current Focus)
- [ ] **Web2 Cryptographic Linking:** Allow users to bind X/Twitter and Discord identities to their ReddID via bio-signature verification.
- [ ] **Encrypted DMs (ECIES):** Utilize the Rust cryptography engine to encrypt IPFS payloads so *only* the recipient's private key can decrypt private social messages.
- [ ] **SPV (Simplified Payment Verification):** Transition from centralized Blockbook indexers to a Light Client model.
