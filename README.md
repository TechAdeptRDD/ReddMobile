# 🔴 ReddMobile: Socially Sustainable Web3 Wallet

ReddMobile is an open-source, non-custodial mobile wallet for the Reddcoin (RDD) ecosystem. It combines a Flutter client with a Rust core for performance-sensitive wallet operations.

> **Status:** Active development. Some roadmap features are documented but not fully implemented yet.

## What ReddMobile Does

- Creates and manages RDD wallets from a mobile-friendly Flutter UI.
- Uses a Rust core (`rust_core`) for native/FFI-backed cryptographic and wallet logic.
- Targets Android and iOS, with multi-platform Flutter scaffolding present.

## Repository Layout

```text
ReddMobile/
├── flutter_app/           # Main Flutter client app
├── rust_core/             # Native Rust library compiled for mobile targets
├── docs/                  # Developer and user documentation
├── .github/workflows/     # CI pipelines
├── CONTRIBUTING.md        # Contribution guidelines
├── SECURITY.md            # Security reporting policy
└── ARCHITECTURE.md        # High-level architecture notes
```

## Prerequisites

- Flutter SDK `3.19.x` (Dart `>=3.3.0 <4.0.0`)
- Rust stable toolchain (`rustup`)
- Android SDK + NDK (for Android builds)
- Xcode + CocoaPods (for iOS builds on macOS)

## Quick Start (Local Development)

### 1) Clone and enter repo

```bash
git clone https://github.com/TechAdeptRDD/ReddMobile.git
cd ReddMobile
```

### 2) Build the Rust core for Android

```bash
cd rust_core
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android
cargo install cargo-ndk --locked
cargo ndk -t arm64-v8a -t armeabi-v7a -t x86_64 -t x86 \
  -o ../flutter_app/android/app/src/main/jniLibs build --release
cd ..
```

### 3) Install Flutter dependencies and run

```bash
cd flutter_app
flutter pub get
flutter run
```

## Dependency Notes

- Flutter dependencies are defined in `flutter_app/pubspec.yaml`.
- Native dependencies are defined in `rust_core/Cargo.toml`.
- Keep dependency updates small and frequent; include changelog notes in PR descriptions for any major upgrades.

## Security and Responsible Disclosure

Please report vulnerabilities through the process in `SECURITY.md`. Avoid opening public issues for undisclosed security vulnerabilities.

## Contributing

Read `CONTRIBUTING.md` before opening a PR. At minimum:

- Run app and tests locally.
- Keep commits focused and explain user impact.
- Include screenshots/GIFs for UI changes.

## License

Licensed under the terms in `LICENSE`.
