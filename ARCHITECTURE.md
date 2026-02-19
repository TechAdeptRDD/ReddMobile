# 🏗️ ReddMobile Systems Architecture

## 1. RDD Protocol Implementation (PoSV v2)
ReddMobile handles Reddcoin as a Social Currency. Unlike traditional PoS, Reddcoin utilizes **Proof of Stake Velocity v2**.
* **Coin Age:** Non-linear aging incentivizes movement (Velocity) over hoarding.
* **Network Snapshot:** The Dashboard displays real-time Network Difficulty and Block Height to provide transparency on PoSV health.

## 2. Social Data Layer (OP_RETURN)
* **Metadata:** Tips can include memos stored in the `OP_RETURN` field of a transaction.
* **Size Limit:** Max 80 bytes per transaction.
* **Parsing:** The `PulseService` decodes these social anchors and filters for printable ASCII to ensure a clean community feed.

## 3. Cryptographic Security
* **Rust Core:** Transaction signing (ECDSA) and Seed derivation occur in the `librust_core.so` FFI boundary.
* **Storage:** Mnemonics are encrypted via OS-level KeyStore/Keychain.
