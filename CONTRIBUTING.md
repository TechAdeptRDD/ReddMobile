# 🛠️ Contributing to ReddMobile

Thank you for your interest in building the future of Reddcoin! ReddMobile is a hybrid application requiring both the Flutter SDK and the Rust Toolchain.

## Local Environment Setup

**1. Install Dependencies**
* Ensure you have Flutter (Stable Channel, v3.19.0 recommended).
* Ensure you have Rust installed.
* Install the Android NDK via Android Studio.

**2. Setup Rust Compilation Targets**
You must add the mobile architectures to your Rust toolchain:

    rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android
    cargo install cargo-ndk

**3. Build the Cryptographic Engine**
Before running the Flutter app, you must compile the Rust backend into C-compatible shared libraries (.so files) and inject them into the Android shell:

    cd rust_core
    cargo ndk -t arm64-v8a -t armeabi-v7a -t x86_64 -t x86 -o ../flutter_app/android/app/src/main/jniLibs build --release

**4. Run the Application**

    cd ../flutter_app
    flutter pub get
    flutter run

## Pull Request Guidelines
* Do not commit to the main branch directly. Create a feature branch (e.g., feat/username-resolution).
* Ensure all Rust code is memory-safe and uses rust_cstr_free for any strings passed over FFI.
* Avoid adding bloated Dart dependencies if the logic can be handled securely in rust_core.
