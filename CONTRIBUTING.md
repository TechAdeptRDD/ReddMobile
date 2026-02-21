# 🛠️ Contributing to ReddMobile

Thanks for helping improve ReddMobile. This guide is optimized for new open-source contributors and repeat maintainers.

## Code of Conduct

Be respectful, constructive, and collaborative in issues and pull requests.

## Development Setup

### 1) Build Rust core (required before running Flutter app)

```bash
cd rust_core
rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android
cargo install cargo-ndk --locked
cargo ndk -t arm64-v8a -t armeabi-v7a -t x86_64 -t x86 \
  -o ../flutter_app/android/app/src/main/jniLibs build --release
cd ..
```

### 2) Install Flutter dependencies

```bash
cd flutter_app
flutter pub get
```

### 3) Run tests and lint

```bash
flutter test
flutter analyze
```

## Branching and Commit Standards

- Create a focused branch per feature/fix.
- Use clear commit messages (e.g., `docs: clarify Android Rust build steps`).
- Keep pull requests small enough to review in one sitting.

## Pull Request Checklist

Before opening a PR, confirm:

- [ ] Code builds locally.
- [ ] Tests pass locally.
- [ ] Any new behavior includes tests or rationale for no tests.
- [ ] Documentation is updated (`README.md`, `docs/`, or inline comments) if behavior changed.
- [ ] UI changes include screenshots for both small and large screens where applicable.
- [ ] Security-sensitive changes describe threat model impact.

## Review Expectations

- PRs should include context, approach, and test evidence.
- Maintainers may ask for scope reduction if a PR is too large.
- Breaking changes must be explicitly flagged in the PR description.

## Security Contributions

For vulnerabilities, follow `SECURITY.md` and avoid posting exploit details in public issues.

## CI & Build Troubleshooting

### Launcher Icon RangeError

If CI fails with:

`RangeError (index): Index out of range: no indices are valid: 0`

Try:

1. Ensure `assets/images/logo.png` is a valid 1024x1024 PNG.
2. Remove `adaptive_icon_background` and `adaptive_icon_foreground` in `pubspec.yaml` if misconfigured.
3. Pin `flutter_launcher_icons` to a known stable version (example: `0.13.1`).
