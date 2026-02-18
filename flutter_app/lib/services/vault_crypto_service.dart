import 'dart:ffi' as ffi;
import 'dart:io';

import 'package:ffi/ffi.dart';

typedef _VaultEncryptC = ffi.Pointer<Utf8> Function(
  ffi.Pointer<Utf8> plaintext,
  ffi.Pointer<Utf8> keyHex,
);
typedef _VaultDecryptC = ffi.Pointer<Utf8> Function(
  ffi.Pointer<Utf8> packedB64,
  ffi.Pointer<Utf8> keyHex,
);
typedef _VaultStringFreeC = ffi.Void Function(ffi.Pointer<Utf8> value);

typedef _VaultEncryptDart = ffi.Pointer<Utf8> Function(
  ffi.Pointer<Utf8> plaintext,
  ffi.Pointer<Utf8> keyHex,
);
typedef _VaultDecryptDart = ffi.Pointer<Utf8> Function(
  ffi.Pointer<Utf8> packedB64,
  ffi.Pointer<Utf8> keyHex,
);
typedef _VaultStringFreeDart = void Function(ffi.Pointer<Utf8> value);

class VaultCryptoService {
  VaultCryptoService() : _lib = _loadLibrary() {
    _encrypt = _lib.lookupFunction<_VaultEncryptC, _VaultEncryptDart>(
      'vault_encrypt',
    );
    _decrypt = _lib.lookupFunction<_VaultDecryptC, _VaultDecryptDart>(
      'vault_decrypt',
    );
    _freeString = _lib.lookupFunction<_VaultStringFreeC, _VaultStringFreeDart>(
      'vault_string_free',
    );
  }

  final ffi.DynamicLibrary _lib;
  late final _VaultEncryptDart _encrypt;
  late final _VaultDecryptDart _decrypt;
  late final _VaultStringFreeDart _freeString;

  static ffi.DynamicLibrary _loadLibrary() {
    if (Platform.isAndroid || Platform.isLinux) {
      return ffi.DynamicLibrary.open('librust_core.so');
    }
    if (Platform.isMacOS || Platform.isIOS) {
      return ffi.DynamicLibrary.open('librust_core.dylib');
    }
    if (Platform.isWindows) {
      return ffi.DynamicLibrary.open('rust_core.dll');
    }
    throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
  }

  String encryptData(String plaintext, String keyHex) {
    final plaintextPtr = plaintext.toNativeUtf8();
    final keyHexPtr = keyHex.toNativeUtf8();

    ffi.Pointer<Utf8> resultPtr = ffi.nullptr;
    try {
      resultPtr = _encrypt(plaintextPtr, keyHexPtr);
      return _parseResult(resultPtr);
    } finally {
      malloc.free(plaintextPtr);
      malloc.free(keyHexPtr);
      if (resultPtr != ffi.nullptr) {
        _freeString(resultPtr);
      }
    }
  }

  String decryptData(String packedB64, String keyHex) {
    final packedB64Ptr = packedB64.toNativeUtf8();
    final keyHexPtr = keyHex.toNativeUtf8();

    ffi.Pointer<Utf8> resultPtr = ffi.nullptr;
    try {
      resultPtr = _decrypt(packedB64Ptr, keyHexPtr);
      return _parseResult(resultPtr);
    } finally {
      malloc.free(packedB64Ptr);
      malloc.free(keyHexPtr);
      if (resultPtr != ffi.nullptr) {
        _freeString(resultPtr);
      }
    }
  }

  String _parseResult(ffi.Pointer<Utf8> resultPtr) {
    if (resultPtr == ffi.nullptr) {
      throw Exception('Rust core returned a null pointer');
    }

    final payload = resultPtr.toDartString();
    if (payload.startsWith('OK:')) {
      return payload.substring(3);
    }
    if (payload.startsWith('ERR:')) {
      throw Exception(payload.substring(4));
    }

    throw Exception('Unexpected response format from Rust core: $payload');
  }
}
