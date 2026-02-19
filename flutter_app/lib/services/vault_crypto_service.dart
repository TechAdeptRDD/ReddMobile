import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef GenerateMnemonicC = ffi.Pointer<Utf8> Function();
typedef GenerateMnemonicDart = ffi.Pointer<Utf8> Function();
typedef DeriveAddressC = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> mnemonic);
typedef DeriveAddressDart = ffi.Pointer<Utf8> Function(ffi.Pointer<Utf8> mnemonic);
typedef FreeStringC = ffi.Void Function(ffi.Pointer<Utf8>);
typedef FreeStringDart = void Function(ffi.Pointer<Utf8>);

class VaultCryptoService {
  late ffi.DynamicLibrary _nativeLib;
  late GenerateMnemonicDart _generateMnemonic;
  late DeriveAddressDart _deriveAddress;
  late FreeStringDart _freeString;

  VaultCryptoService() {
    _nativeLib = ffi.DynamicLibrary.open("librust_core.so");
    _generateMnemonic = _nativeLib.lookup<ffi.NativeFunction<GenerateMnemonicC>>('generate_mnemonic_ffi').asFunction();
    _deriveAddress = _nativeLib.lookup<ffi.NativeFunction<DeriveAddressC>>('derive_address_ffi').asFunction();
    _freeString = _nativeLib.lookup<ffi.NativeFunction<FreeStringC>>('rust_cstr_free').asFunction();
  }

  String generateNewMnemonic() {
    final pointer = _generateMnemonic();
    final mnemonic = pointer.toDartString();
    _freeString(pointer);
    return mnemonic;
  }

  String deriveReddcoinAddress(String mnemonic) {
    final mnemonicPtr = mnemonic.toNativeUtf8();
    final pointer = _deriveAddress(mnemonicPtr);
    final address = pointer.toDartString();
    _freeString(pointer);
    malloc.free(mnemonicPtr);
    return address;
  }

  // Matches DashboardBloc call: vaultCryptoService.signMultiInputTransaction(...)
  String signMultiInputTransaction({
    String privateKeyHex = "", 
    List<dynamic> utxos = const [],
    String destination = "", 
    double amount = 0.0,
    String changeAddress = "",
    double feePerKb = 1000.0,
  }) {
    return "mock_signed_tx_hex_v0.5.2"; 
  }
}
