# 🔴 ReddMobile

ReddMobile is an open-source, non-custodial mobile wallet for the Reddcoin ecosystem. The project combines a Flutter application (`flutter_app`) with a Rust cryptography/signing core (`rust_core`) exposed over FFI.

> **Project state:** Phase 1 (Baseline Audit) and Phase 2 (Vertical Slices) are complete. This repository now emphasizes Phase 3 quality: documentation, developer experience, and consistency hardening.

## Current Feature Set

- Wallet onboarding with mnemonic generation/verification flows.
- Dashboard balance + transaction history sourced from Blockbook.
- Transaction creation + broadcast pipeline for standard sends and OP_RETURN use cases.
- Social/identity-adjacent slices (Pulse and ReddID scaffolding).
- Local secure persistence for wallet material and cache metadata.

## Repository Structure

```text
ReddMobile/
├── flutter_app/                 # Flutter client (UI, BLoC slices, services)
├── rust_core/                   # Rust FFI library for signing/crypto helpers
├── docs/                        # Additional end-user + developer docs
├── .github/                     # CI and contribution templates
├── ARCHITECTURE.md              # Deep architecture and slice interaction guide
├── CONTRIBUTING.md              # Onboarding + contribution workflow
├── SECURITY.md                  # Security disclosure process
└── README.md
```

## Prerequisites

- Flutter SDK `3.22.x` (stable channel recommended)
- Dart SDK `>=3.3.0 <4.0.0`
- Rust stable toolchain via `rustup`
- Android SDK + NDK (for Android builds)
- Xcode + CocoaPods (for iOS builds on macOS)

## Quick Start

### 1) Clone

```bash
git clone https://github.com/TechAdeptRDD/ReddMobile.git
cd ReddMobile
```

### 2) Build Rust Android libraries

```bash
cd rust_core
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android
cargo install cargo-ndk --locked
cargo ndk -t arm64-v8a -t armeabi-v7a -t x86_64 \
  -o ../flutter_app/android/app/src/main/jniLibs build --release
cd ..
```

### 3) Install Flutter dependencies

```bash
cd flutter_app
flutter pub get
```

### 4) Run locally

```bash
flutter run
```

## Runtime Endpoints

ReddMobile’s blockchain service integration is standardized on:

- `https://blockbook.reddcoin.com`

Any documentation, config examples, or code references should use this domain.

## Common Validation Commands

From `flutter_app/`:

```bash
flutter analyze
flutter test
```

From `rust_core/`:

```bash
cargo check
```

## Contributing

Please read [`CONTRIBUTING.md`](./CONTRIBUTING.md) before opening a PR. For architecture context, start with [`ARCHITECTURE.md`](./ARCHITECTURE.md).

## Security

If you discover a vulnerability, follow the private reporting process in [`SECURITY.md`](./SECURITY.md).

## License

This repository is licensed under the terms in [`LICENSE`](./LICENSE).
