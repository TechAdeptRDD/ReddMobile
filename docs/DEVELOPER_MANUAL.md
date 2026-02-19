# 🛠️ ReddMobile Developer Manual (Technical Architecture)

## 1. The FFI Bridge (Native Handshake)
The app uses **Dart FFI** to communicate with `rust_core`. 
* **Rust Entry:** `rust_core/src/lib.rs`
* **Dart Bridge:** `lib/services/vault_crypto_service.dart`

**Data Flow:**
1. Dart encodes data (e.g., UTXOs) to JSON strings.
2. Dart converts strings to `Pointer<Utf8>`.
3. Rust receives the pointer, performs crypto operations, and returns a new pointer to a hex-encoded transaction.
4. Dart reads the string and cleans up memory using `malloc.free()`.

## 2. BLoC State Management
We utilize the **BLoC (Business Logic Component)** pattern to separate UI from logic.
* **DashboardBloc:** Manages balance and transaction broadcasting.
* **ActivityBloc:** Manages the transaction history state.
* **Navigation:** Blocs are provided globally in `main.dart` to prevent `ProviderNotFoundException` during screen transitions.

## 3. The CI/CD Pipeline (Release Factory)
The project uses GitHub Actions (`.github/workflows/android_build.yml`) to:
1.  **Cross-Compile Rust:** Uses `cargo-ndk` to build for `arm64-v8a`.
2.  **Bundle Assets:** Copies `.so` files into `android/app/src/main/jniLibs`.
3.  **Build Flutter:** Compiles the APK with `--dart-define` versioning.
4.  **Auto-Release:** Creates a GitHub Release upon a version tag (e.g., `v0.1.3`).

## 4. Troubleshooting Build Errors
* **"Missing Clang":** Ensure `ANDROID_NDK_HOME` is set in the build environment.
* **"ProviderNotFound":** Always check that the Bloc is provided in `main.dart` above the `MaterialApp`.
