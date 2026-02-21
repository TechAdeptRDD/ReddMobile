# 🏗️ ReddMobile Architecture

This document explains how ReddMobile is organized, how the vertical slices interact, and where wallet-critical logic lives.

## 1. System Overview

ReddMobile is split into two execution environments:

1. **Flutter app (`flutter_app`)**
   - Presentation layer (screens/widgets)
   - State orchestration (BLoC)
   - Network/data services
2. **Rust core (`rust_core`)**
   - Cryptographic and transaction-construction primitives
   - FFI-compatible functions callable from Dart

The guiding rule is: **UI and orchestration in Flutter; deterministic crypto/signing in Rust.**

---

## 2. Vertical Slice Model

Each major feature is implemented as a vertical slice with clear ownership.

### Onboarding Slice
- BLoC: `lib/bloc/onboarding/`
- Responsibilities:
  - New wallet creation and phrase verification flow
  - Initial state transitions before dashboard access

### Dashboard Slice
- BLoC: `lib/bloc/dashboard/`
- Responsibilities:
  - Wallet address resolution
  - Balance/history retrieval
  - Fiat display enrichment

### Activity Slice
- BLoC: `lib/bloc/activity/`
- Responsibilities:
  - Transaction list retrieval and state handling

### ReddID / Pulse Slice
- Pages + services:
  - `lib/pages/reddid_registration_page.dart`
  - `lib/services/reddid_service.dart`
  - `lib/services/pulse_service.dart`
- Responsibilities:
  - Social metadata/identity workflows
  - OP_RETURN-adjacent read/write interactions

---

## 3. State Management Strategy

ReddMobile uses the **BLoC pattern** (`flutter_bloc`) with immutable states and explicit events.

### Why this approach
- Predictable state transitions for async-heavy wallet flows.
- Strong separation between UI and side effects.
- Testability of domain behavior without full widget trees.

### State flow pattern
1. UI dispatches event (`LoadDashboardData`, etc.).
2. BLoC invokes services (`BlockbookService`, secure storage, crypto helper).
3. BLoC emits loading/success/error states.
4. UI renders pure state.

---

## 4. Wallet & Key Handling

### Mnemonic lifecycle
- Mnemonics are generated/managed in application flow.
- Sensitive values are persisted via secure platform storage (`flutter_secure_storage` abstraction).

### Address derivation and signing
- Flutter coordinates user intent and payload collection.
- Rust functions perform deterministic signing/building for transaction payloads.
- FFI calls pass plain UTF-8 strings and return string outputs (e.g., signed hex).

### Security boundaries
- Wallet secrets should remain in secure storage and memory only as long as necessary.
- Network failures must not result in key material leakage.
- Validation is performed before broadcast to avoid avoidable node rejections.

---

## 5. Blockchain Sync and Data Access

`BlockbookService` is the canonical chain-data adapter.

### Endpoint baseline
- Base URL: `https://blockbook.reddcoin.com`

### Reliability behavior
- HTTPS-only URI validation.
- Request timeout + bounded retries.
- Exponential backoff + jitter for transient failures.
- Lightweight cache for network info and address details.
- In-flight deduplication to prevent duplicate concurrent GETs.

This keeps wallet UX responsive under intermittent node/network instability.

---

## 6. Transaction Engine (Rust)

Key modules:
- `transaction_builder.rs`: protocol payload encoding (including OP_RETURN constraints).
- `transaction_signer.rs`: UTXO validation, fee estimation, dust handling, and P2PKH signature assembly.
- `vault_crypto.rs`: authenticated encryption/decryption helpers.

Design intent:
- Fail fast with explicit error messages.
- Keep script/fee assumptions explicit and documented.
- Return serialization-friendly outputs for Flutter transport and node broadcast.

---

## 7. CI and Quality Gates

Primary workflow: `.github/workflows/flutter_build.yml`

- Pull Requests:
  - `flutter analyze`
  - `flutter test`
- Tagged releases:
  - Rust Android library build
  - Flutter release APK build
  - GitHub Release artifact upload

---

## 8. Evolution Guidance

When extending the app:
- Prefer adding functionality inside existing slices before introducing new cross-cutting globals.
- Keep user-facing strings clear, actionable, and consistent.
- Keep external domain references standardized to `blockbook.reddcoin.com` where relevant.
