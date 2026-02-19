import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';

// Define the C function signature
typedef GenerateMnemonicC = ffi.Pointer<Utf8> Function();
typedef GenerateMnemonicDart = ffi.Pointer<Utf8> Function();

typedef FreeStringC = ffi.Void Function(ffi.Pointer<Utf8>);
typedef FreeStringDart = void Function(ffi.Pointer<Utf8>);

class VaultCryptoService {
  late ffi.DynamicLibrary _nativeLib;
  late GenerateMnemonicDart _generateMnemonic;
  late FreeStringDart _freeString;

  VaultCryptoService() {
    if (Platform.isAndroid) {
      _nativeLib = ffi.DynamicLibrary.open("librust_core.so");
    } else {
      _nativeLib = ffi.DynamicLibrary.open("librust_core.so"); // Fallback
    }

    // Lookup the generate function
    _generateMnemonic = _nativeLib
        .lookup<ffi.NativeFunction<GenerateMnemonicC>>('generate_mnemonic_ffi')
        .asFunction();

    // Lookup the memory cleanup function
    _freeString = _nativeLib
        .lookup<ffi.NativeFunction<FreeStringC>>('rust_cstr_free')
        .asFunction();
  }

  /// Generates a real BIP39 Mnemonic Phrase (12 Words) from Rust
  String generateNewMnemonic() {
    final pointer = _generateMnemonic();
    final String mnemonic = pointer.toDartString();
    _freeString(pointer); // Important: Free memory on Rust side
    return mnemonic;
  }

  // --- Mocks below for UI stability while we build out the rest --- //
  
  String signMultiInputTransaction({
    String privateKeyHex = "", 
    List<dynamic> utxos = const [],
    String destination = "", 
    double amount = 0.0,
    String changeAddress = "",
    double feePerKb = 1000.0,
    String? opReturnData,
  }) {
    return "mock_signed_tx_hex_v0.2.0"; 
  }

  String signTransaction(String txData) {
    return "Signed: $txData"; 
  }
}
