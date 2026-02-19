# 🛠️ Contributing to ReddMobile

## Local Environment Setup

**1. Rust Compilation**
You must compile the Rust core before the Flutter app will run:
    
    cd rust_core
    rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android
    cargo ndk -t arm64-v8a -t armeabi-v7a -t x86_64 -t x86 -o ../flutter_app/android/app/src/main/jniLibs build --release

**2. Flutter Dependencies**
Ensure you are using the pinned versions in `pubspec.yaml` to satisfy the Dart 3.3.0 CI constraints.

**3. Pull Requests**
* Code must be linted.
* Rust functions must include unit tests in `lib.rs`.
* UI changes must be verified on both Small (Pixel 4) and Large (Tablet) screen formats.

## CI & Build Troubleshooting
### Launcher Icon RangeError
If the CI fails with `RangeError (index): Index out of range: no indices are valid: 0` during the icon generation step:
1. Ensure `assets/images/logo.png` is a standard 1024x1024 PNG (no transparency preferred for iOS).
2. Simplify `pubspec.yaml` by removing `adaptive_icon_background` and `adaptive_icon_foreground`.
3. Use a static version of `flutter_launcher_icons` (e.g., `0.13.1`).
