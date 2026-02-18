import 'package:flutter/foundation.dart';
import 'ffi_stub.dart' if (dart.library.io) 'dart:ffi' as ffi;
import 'ffi_stub.dart' if (dart.library.io) 'package:ffi/ffi.dart';

// --- FFI Signature Mapping ---

// 1. Generate Payload
typedef GeneratePayloadC = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> command, ffi.Pointer<Utf8> identifier);
typedef GeneratePayloadDart = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> command, ffi.Pointer<Utf8> identifier);

// 2. Sign Transaction (Mapping the new Rust function)
typedef SignTxC = ffi.Pointer<Utf8> Function(
  ffi.Pointer<Utf8> privateKeyHex,
  ffi.Pointer<Utf8> utxoTxid,
  ffi.Uint32 utxoVout,
  ffi.Uint64 utxoAmount,
  ffi.Pointer<Utf8> opReturnPayload,
  ffi.Pointer<Utf8> changeAddress,
  ffi.Uint64 networkFee
);

typedef SignTxDart = ffi.Pointer<Utf8> Function(
  ffi.Pointer<Utf8> privateKeyHex,
  ffi.Pointer<Utf8> utxoTxid,
  int utxoVout,
  int utxoAmount,
  ffi.Pointer<Utf8> opReturnPayload,
  ffi.Pointer<Utf8> changeAddress,
  int networkFee
);

class VaultCryptoService {
  late GeneratePayloadDart _generatePayloadNative;
  late SignTxDart _signTxNative;

  VaultCryptoService() {
    if (kIsWeb) {
      debugPrint("VaultCryptoService: Running in Web Mock mode.");
    } else {
      _initNative();
    }
  }

  void _initNative() {
    final dylib = ffi.DynamicLibrary.open('/workspaces/ReddMobile/rust_core/target/release/librust_core.so');
    _generatePayloadNative = dylib.lookupFunction<GeneratePayloadC, GeneratePayloadDart>('generate_reddid_payload_ffi');
    _signTxNative = dylib.lookupFunction<SignTxC, SignTxDart>('sign_opreturn_transaction_ffi');
  }

  String generateOpReturnPayload(String command, String identifier) {
    if (kIsWeb) return "WEB_MOCK_PAYLOAD_${command.toUpperCase()}_${identifier.toUpperCase()}";

    final cmdPtr = command.toNativeUtf8();
    final idPtr = identifier.toNativeUtf8();
    final resultPtr = _generatePayloadNative(cmdPtr, idPtr);
    final resultString = resultPtr.toDartString();
    
    calloc.free(cmdPtr);
    calloc.free(idPtr);
    return resultString;
  }

  /// Passes UTXO data to Rust to construct and sign a raw Reddcoin transaction.
  String signOpReturnTransaction({
    required String privateKeyHex,
    required String utxoTxid,
    required int utxoVout,
    required int utxoAmount,
    required String opReturnPayload,
    required String changeAddress,
    required int networkFee,
  }) {
    if (kIsWeb) {
      return "WEB_MOCK_SIGNED_TX_FOR_$utxoTxid";
    }

    final pkPtr = privateKeyHex.toNativeUtf8();
    final txidPtr = utxoTxid.toNativeUtf8();
    final payloadPtr = opReturnPayload.toNativeUtf8();
    final changePtr = changeAddress.toNativeUtf8();

    final resultPtr = _signTxNative(
      pkPtr, txidPtr, utxoVout, utxoAmount, payloadPtr, changePtr, networkFee
    );
    
    final resultString = resultPtr.toDartString();

    calloc.free(pkPtr);
    calloc.free(txidPtr);
    calloc.free(payloadPtr);
    calloc.free(changePtr);

    return resultString;
  }

  String encryptData(String plaintext, String keyHex) => kIsWeb ? "WEB_MOCK_ENCRYPTED" : "NATIVE_ENCRYPTED";
  String decryptData(String packedB64, String keyHex) => kIsWeb ? "WEB_MOCK_DECRYPTED" : "NATIVE_DECRYPTED";
}
