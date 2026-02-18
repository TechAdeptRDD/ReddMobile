import 'package:flutter_test/flutter_test.dart';
import 'package:redd_mobile/services/vault_crypto_service.dart';

void main() {
  test('Rust Signer should handle multiple UTXO inputs via JSON bridge', () {
    final crypto = VaultCryptoService();

    final mockUtxos = [
      {"txid": "a" * 64, "vout": 0, "amount": 500000000},
      {"txid": "b" * 64, "vout": 1, "amount": 500000000},
    ];

    // Note: The service now hex-encodes this internally
    final result = crypto.signMultiInputTransaction(
      utxos: mockUtxos,
      privateKeyHex: "1" * 64, 
      opReturnData: "nsbid:tech", // "nsbid:tech" is 10 chars -> 20 hex digits (Even!)
      changeAddress: "Rmhzj1f9DmyzQnXZKnrXz4F2J2rMrcNf6K",
      feePerKb: 1000,
    );

    print("Signed Hex: $result");
    expect(result, isNot(contains("ERR")));
    expect(result.length, greaterThan(100)); 
  });
}
