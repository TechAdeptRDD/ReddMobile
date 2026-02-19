# 🛡️ ReddMobile Security Model

## 1. Memory Safety
By utilizing Rust for transaction construction, we prevent common memory-based attacks (buffer overflows) that plague traditional C++ wallet implementations.

## 2. Biometric Enforcement
Every sensitive action (Revealing Seed, Sending RDD, Generating Web2 Signatures) requires mandatory OS-level biometric authentication via the `LocalAuthentication` package.

## 3. Privacy
* **No Tracking:** No telemetry or analytics are included.
* **Local Identity:** Your ReddID is your own; the developers have no master access to handles or avatars.
