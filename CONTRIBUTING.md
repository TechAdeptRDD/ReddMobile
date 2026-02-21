# 🛠️ Contributing to ReddMobile

Thanks for contributing to ReddMobile. This guide is intended to reduce setup friction and improve review quality.

## 1) Before You Start

- Read [`README.md`](./README.md) and [`ARCHITECTURE.md`](./ARCHITECTURE.md).
- Search existing issues/PRs to avoid duplicate work.
- For security-sensitive findings, use [`SECURITY.md`](./SECURITY.md) (do not open public exploit issues).

## 2) Local Development Setup

## Prerequisites

- Flutter `3.22.x` (stable)
- Rust stable (`rustup`)
- Android SDK + NDK for Android development
- Xcode + CocoaPods for iOS development (macOS)

### Step A — Clone

```bash
git clone https://github.com/TechAdeptRDD/ReddMobile.git
cd ReddMobile
```

### Step B — Build Rust core for Android

```bash
cd rust_core
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android
cargo install cargo-ndk --locked
cargo ndk -t arm64-v8a -t armeabi-v7a -t x86_64 \
  -o ../flutter_app/android/app/src/main/jniLibs build --release
cd ..
```

### Step C — Install Flutter dependencies

```bash
cd flutter_app
flutter pub get
```

### Step D — Run app

```bash
flutter run
```

## 3) Build and Test Commands

Run from `flutter_app/` unless noted.

```bash
flutter analyze
flutter test
```

Rust checks from `rust_core/`:

```bash
cargo check
```

## 4) Branching and Commits

- Use focused branches (`feat/...`, `fix/...`, `docs/...`, `chore/...`).
- Keep commits scoped and descriptive.
- Rebase/squash where useful to keep history readable.

## 5) Pull Request Expectations

Use the repository PR template and include:

- Problem statement and user/developer impact.
- Scope boundaries (what is intentionally out of scope).
- Validation evidence (commands + outputs).
- Screenshots for UI changes.

### PR Checklist

- [ ] App builds locally for touched platform(s).
- [ ] `flutter analyze` passes.
- [ ] `flutter test` passes.
- [ ] `cargo check` run if `rust_core` changed.
- [ ] Docs updated for behavior/config changes.
- [ ] No secrets or private keys committed.

## 6) Issue Quality Standards

When opening issues, include:

- Current behavior
- Expected behavior
- Reproduction steps
- Environment (OS/device, Flutter version, branch/commit)
- Logs/screenshots where helpful

## 7) Domain Consistency Rule

ReddMobile’s blockchain endpoint references must use:

- `https://blockbook.reddcoin.com`

Do not introduce references to legacy domains in docs, comments, or configuration examples.
