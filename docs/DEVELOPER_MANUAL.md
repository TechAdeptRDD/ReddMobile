# 🛠️ ReddMobile Developer Manual

## FFI Bridge: Flutter ↔ Rust

ReddMobile uses Dart FFI to invoke selected Rust functions for crypto-sensitive operations.

- Rust entry: `rust_core/src/lib.rs`
- Rust transaction/crypto modules: `rust_core/src/transaction_signer.rs`, `rust_core/src/vault_crypto.rs`, `rust_core/src/transaction_builder.rs`
- Flutter service facade: `flutter_app/lib/services/vault_crypto_service.dart`

### Data flow summary

1. Flutter assembles inputs (mnemonic, UTXOs, payloads).
2. Inputs are serialized to UTF-8/JSON strings across FFI.
3. Rust validates, signs/builds payloads, and returns serialized outputs.
4. Flutter forwards signed hex to Blockbook broadcast endpoints.

## State Management

The Flutter app uses BLoC for feature slices.

- `DashboardBloc`: address derivation, balance/history load, fiat enrichment.
- `ActivityBloc`: transaction feed loading.
- `OnboardingBloc`: wallet setup progression.

This separation keeps UI widgets declarative and isolates side effects in blocs/services.

## Networking and Sync

`BlockbookService` is the chain data adapter. It includes:

- HTTPS-only endpoint enforcement
- Retries with exponential backoff + jitter
- Timeout handling
- Lightweight response caching
- In-flight request deduplication

Canonical endpoint domain:

- `https://blockbook.reddcoin.com`

## CI/CD

Primary workflow: `.github/workflows/flutter_build.yml`

- PR checks: `flutter analyze`, `flutter test`
- Release tags: Rust Android library build + Flutter APK build + release publishing

## Troubleshooting

- **Android Rust build fails:** verify NDK is installed and target triples were added with `rustup target add ...`.
- **BLoC provider errors:** ensure blocs are injected above consuming widgets in `main.dart`.
- **Node fetch instability:** check endpoint reachability for `blockbook.reddcoin.com` and rerun with logs.
