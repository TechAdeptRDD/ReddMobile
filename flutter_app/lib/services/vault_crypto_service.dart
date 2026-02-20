import 'dart:ffi';
import 'dart:io';

class VaultCryptoService {
  final DynamicLibrary _rustLib = Platform.isAndroid
      ? DynamicLibrary.open("librust_core.so")
      : DynamicLibrary.process();

  String generateNewMnemonic() =>
      "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
  String generateMnemonic() => generateNewMnemonic();
  String deriveReddcoinAddress(String mnemonic) => "R_PlaceholderAddress";
  String generateSocialSignature(String message, String privateKey) =>
      "signature_placeholder";

  // Highly permissive method signature to accept any legacy arguments thrown at it
  String signMultiInputTransaction(
          {dynamic utxos,
          String? toAddress,
          String? destination,
          double? amount,
          String? mnemonic,
          String? privateKeyHex,
          String? changeAddress,
          String? opReturnData,
          dynamic inputs}) =>
      "mock_signed_hex";

  String encryptData(String data, String key) => "encrypted_$data";
  String decryptData(String cipher, String key) =>
      cipher.replaceAll("encrypted_", "");
}
