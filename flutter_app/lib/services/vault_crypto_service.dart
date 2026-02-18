import 'dart:ffi' as ffi;
import 'package:ffi/ffi.dart';
import 'dart:convert';
import 'dart:io';

class VaultCryptoService {
  late ffi.DynamicLibrary _nativeLib;

  VaultCryptoService() {
    _nativeLib = ffi.DynamicLibrary.open('/workspaces/ReddMobile/rust_core/target/release/librust_core.so');
  }

  // STANDARD SEND (P2PKH)
  String signStandardTransfer({
    required List<Map<String, dynamic>> utxos,
    required String privateKeyHex,
    required String recipientAddress,
    required String changeAddress,
    required int amountToSend,
    required int feePerKb,
  }) {
    final utxosJson = jsonEncode(utxos);
    final signFunc = _nativeLib.lookupFunction<
        ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Uint64, ffi.Uint64),
        ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, int, int)
    >('sign_standard_transfer_ffi');

    final utxosPtr = utxosJson.toNativeUtf8();
    final keyPtr = privateKeyHex.toNativeUtf8();
    final recvPtr = recipientAddress.toNativeUtf8();
    final changePtr = changeAddress.toNativeUtf8();

    final resultPtr = signFunc(utxosPtr, keyPtr, recvPtr, changePtr, amountToSend, feePerKb);
    final result = resultPtr.toDartString();

    malloc.free(utxosPtr);
    malloc.free(keyPtr);
    malloc.free(recvPtr);
    malloc.free(changePtr);

    return result;
  }

  // REDDID BID (OP_RETURN)
  String signMultiInputTransaction({
    required List<Map<String, dynamic>> utxos,
    required String privateKeyHex,
    required String opReturnData,
    required String changeAddress,
    required int feePerKb,
  }) {
    final utxosJson = jsonEncode(utxos);
    final signFunc = _nativeLib.lookupFunction<
        ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Uint64),
        ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, ffi.Pointer<Utf8>, int)
    >('sign_multi_input_transaction_ffi');

    final utxosPtr = utxosJson.toNativeUtf8();
    final keyPtr = privateKeyHex.toNativeUtf8();
    final dataPtr = hexEncode(opReturnData).toNativeUtf8();
    final addressPtr = changeAddress.toNativeUtf8();

    final resultPtr = signFunc(utxosPtr, keyPtr, dataPtr, addressPtr, feePerKb);
    final result = resultPtr.toDartString();

    malloc.free(utxosPtr);
    malloc.free(keyPtr);
    malloc.free(dataPtr);
    malloc.free(addressPtr);

    return result;
  }

  String decryptData(String blob, String password) => "decrypted_key_mock"; 
  String generateOpReturnPayload(String prefix, String handle) => "6a0a${hexEncode(prefix + handle)}";
  
  String hexEncode(String input) => input.runes.map((r) => r.toRadixString(16)).join();
}
