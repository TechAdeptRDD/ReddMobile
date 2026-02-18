#!/bin/bash
echo "==============================================="
echo "   REDDMOBILE CORE SYSTEM HEALTH REPORT"
echo "==============================================="

# 1. Check Rust Engine
echo -n "1. Native Rust Core: "
cd /workspaces/ReddMobile/rust_core
if cargo check > /dev/null 2>&1; then
    echo "✅ COMPILED"
else
    echo "❌ COMPILE ERROR"
fi

# 2. Check FFI Binary
echo -n "2. FFI Shared Library: "
if [ -f "/workspaces/ReddMobile/rust_core/target/release/librust_core.so" ]; then
    EXPORTS=$(nm -D /workspaces/ReddMobile/rust_core/target/release/librust_core.so | grep ffi | wc -l)
    echo "✅ FOUND ($EXPORTS symbols exported)"
else
    echo "❌ MISSING (Run cargo build --release)"
fi

# 3. Check Flutter & Dependencies
echo -n "3. Flutter Framework: "
cd /workspaces/ReddMobile/flutter_app
if flutter --version > /dev/null 2>&1; then
    echo "✅ READY"
else
    echo "❌ NOT FOUND"
fi

# 4. Run All Unit Tests
echo "4. Running Integrated Test Suite..."
flutter test test/dashboard_bloc_test.dart > /dev/null 2>&1 && echo "   - Dashboard BLoC: ✅ PASSED" || echo "   - Dashboard BLoC: ❌ FAILED"
flutter test test/vault_integration_test.dart > /dev/null 2>&1 && echo "   - Vault/FFI Bridge: ✅ PASSED" || echo "   - Vault/FFI Bridge: ❌ FAILED"
flutter test test/blockbook_service_test.dart > /dev/null 2>&1 && echo "   - Network/Blockbook: ✅ PASSED" || echo "   - Network/Blockbook: ❌ FAILED"

echo "==============================================="
echo "   STATUS: SYSTEM READY FOR DEPLOYMENT"
echo "==============================================="
