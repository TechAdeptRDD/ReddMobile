# ReddMobile 📱💰

ReddMobile is a production-grade, high-security mobile wallet for the **Reddcoin (RDD)** network. It combines the sleek, cross-platform UI of **Flutter** with a rock-solid, native **Rust** cryptographic core.

## 🚀 Features

* **ReddID Native Support:** Search, check availability, and bid on ReddID handles directly from the dashboard.
* **Hybrid Architecture:** All sensitive cryptographic operations and transaction signing happen in a native Rust "Vault" via FFI.
* **Multi-Input Logic:** Sophisticated coin selection and UTXO management to handle fragmented balances and automatic change calculation.
* **Real-time Activity:** Live-synced transaction history powered by Blockbook API integration.
* **Glassmorphism UI:** A premium, modern Obsidian-themed interface designed for the next generation of social currency users.

## 🏗️ Architecture

ReddMobile utilizes a **Sign-and-Broadcast** pipeline:

1.  **State Management:** Flutter BLoC handles the application logic and UI states.
2.  **Security Engine:** A custom Rust library (\`rust_core\`) manages private keys and signs transactions using the \`bitcoin\` and \`secp256k1\` crates.
3.  **Data Layer:** Integration with Blockbook for UTXO fetching, address history, and transaction broadcasting.



## 🛠️ Tech Stack

* **Frontend:** [Flutter](https://flutter.dev) (Dart)
* **Core:** [Rust](https://www.rust-lang.org) (ECDSA Signing, Transaction Building)
* **Bridge:** Dart FFI (Foreign Function Interface)
* **Backend:** Blockbook API (Reddcoin implementation)

## 📂 Project Structure

* \`/flutter_app\`: The mobile application code.
* \`/rust_core\`: The native Rust library for cryptographic operations.
* \`/docs\`: Detailed User and Developer documentation.

## 🛠️ Development

### Prerequisites
* Flutter SDK
* Rust (Cargo)
* Android NDK / LLVM (for FFI compilation)

### Build the Rust Core
\`\`\`bash
cd rust_core
cargo build --release
\`\`\`

### Run the App
\`\`\`bash
cd flutter_app
flutter run
\`\`\`

## 📜 Documentation
* [User Guide](./docs/USER_GUIDE.md)
* [Developer Manual](./docs/DEVELOPER_MANUAL.md)

---
**Maintained by TechAdeptRDD** *Building the future of social currency, one block at a time.*
