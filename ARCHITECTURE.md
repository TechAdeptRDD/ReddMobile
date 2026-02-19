# 🏗️ ReddMobile Systems Architecture

## 1. Cryptographic Bridge (Rust <-> Dart)
ReddMobile uses a "Zero-Visibility" model for private keys:
* **Storage:** Mnemonics are encrypted in the Hardware Secure Enclave (Keystore/Keychain).
* **Signing:** The `VaultCryptoService` passes encrypted data to `librust_core.so`.
* **Verification:** Rust performs ECDSA signing and returns only the public HEX to Dart.

## 2. Identity Stack (ReddID + IPFS)
* **Storage:** Avatars are pinned to IPFS using `IpfsService` via native multipart uploads.
* **On-Chain:** The CID and Handle are committed to the blockchain via `OP_RETURN` payloads.
* **Resolution:** The `BlockbookService` parses transaction history to resolve handles back to wallet addresses.

## 3. Localization & Oracle Layer
* **Pricing:** The `DashboardBloc` polls the CoinGecko API based on the user's `fiat_pref` stored in `SecureStorageService`.
* **QR Logic:** The `ScanPage` utilizes `mobile_scanner` to parse `redd://pay` deep links and raw RDD addresses.
