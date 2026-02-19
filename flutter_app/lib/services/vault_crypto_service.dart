import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'dart:io';

// --- FFI Signature Definitions ---
typedef GenerateMnemonicC = Pointer<Utf8> Function();
typedef GenerateMnemonicDart = Pointer<Utf8> Function();

typedef DeriveAddressC = Pointer<Utf8> Function(Pointer<Utf8> mnemonic);
typedef DeriveAddressDart = Pointer<Utf8> Function(Pointer<Utf8> mnemonic);

typedef SignTxC = Pointer<Utf8> Function(Pointer<Utf8> jsonRequest);
typedef SignTxDart = Pointer<Utf8> Function(Pointer<Utf8> jsonRequest);

typedef FreeStringC = Void Function(Pointer<Utf8> ptr);
typedef FreeStringDart = void Function(Pointer<Utf8> ptr);

class VaultCryptoService {
  late DynamicLibrary _rustLib;

  VaultCryptoService() {
    _rustLib = Platform.isAndroid 
        ? DynamicLibrary.open("librust_core.so") 
        : DynamicLibrary.process(); // Fallback for iOS/Test environments
  }

  // 1. THE MISSING METHOD: Generate a new 12-word seed phrase via Rust
  String generateMnemonic() {
    final generateFunc = _rustLib.lookupFunction<GenerateMnemonicC, GenerateMnemonicDart>('generate_mnemonic_ffi');
    final freeFunc = _rustLib.lookupFunction<FreeStringC, FreeStringDart>('rust_cstr_free');

    final ptr = generateFunc();
    final result = ptr.toDartString();
    freeFunc(ptr); // Prevent memory leak
    return result;
  }

  // 2. Derive Reddcoin Address
  // 4. Generate Web2 Social Proof Signature (UI Placeholder for Rust FFI)
  String generateSocialSignature(String address, String platform) {
    // In the next Rust sprint, this will pass the mnemonic and message to k256 for a true ECDSA signature.
    // For this UI build, we generate a deterministic formatted string.
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(0, 8);
    final payload = "redd_sig:${platform.toLowerCase()}_${address.substring(0,8)}_$timestamp";
    return payload;
  }

  String deriveReddcoinAddress(String mnemonic) {
    final deriveFunc = _rustLib.lookupFunction<DeriveAddressC, DeriveAddressDart>('derive_address_ffi');
    final freeFunc = _rustLib.lookupFunction<FreeStringC, FreeStringDart>('rust_cstr_free');

    final mnemonicPtr = mnemonic.toNativeUtf8();
    final resultPtr = deriveFunc(mnemonicPtr);
    
    final result = resultPtr.toDartString();
    
    malloc.free(mnemonicPtr);
    freeFunc(resultPtr);
    
    return result;
  }

  // 3. Sign Transaction (Using the JSON protocol we built)
  String signMultiInputTransaction({
    required String privateKeyHex, 
    required List<dynamic> utxos,
    required String destination,
    required double amount,
    required String changeAddress,
    String? opReturnData,
  }) {
    final signFunc = _rustLib.lookupFunction<SignTxC, SignTxDart>('build_and_sign_tx_ffi');
    final freeFunc = _rustLib.lookupFunction<FreeStringC, FreeStringDart>('rust_cstr_free');

    // Convert flutter utxos map into the JSON format expected by our Rust struct
    String utxoJson = "[";
    for(int i = 0; i < utxos.length; i++) {
       final txid = utxos[i]['txid'];
       final vout = utxos[i]['vout'];
       final value = utxos[i]['value'];
       utxoJson += '{"txid":"$txid","vout":$vout,"value":$value}';
       if(i < utxos.length - 1) utxoJson += ",";
    }
    utxoJson += "]";

    // We hardcode 0.001 RDD fee for now.
    final int amountSats = (amount * 100000000).toInt();
    final int feeSats = 100000;

    String jsonRequest = '''
    {
      "mnemonic": "$privateKeyHex",
      "destination_address": "$destination",
      "amount_sats": $amountSats,
      "change_address": "$changeAddress",
      "fee_sats": $feeSats,
      "utxos": $utxoJson
    ''';

    if (opReturnData != null) {
      jsonRequest += ',\n"op_return_data": "$opReturnData"';
    }
    jsonRequest += '\n}';

    final jsonPtr = jsonRequest.toNativeUtf8();
    final resultPtr = signFunc(jsonPtr);
    
    final signedHex = resultPtr.toDartString();
    
    malloc.free(jsonPtr);
    freeFunc(resultPtr);
    
    return signedHex;
  }
}
