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
