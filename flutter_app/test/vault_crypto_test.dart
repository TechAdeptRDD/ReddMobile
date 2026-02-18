import 'package:flutter_test/flutter_test.dart';

import '../lib/services/vault_crypto_service.dart';

void main() {
  const validTestKeyHex =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';

  group('Sovereign Vault - Cryptographic FFI Tests', () {
    final vaultCryptoService = VaultCryptoService();

    test('Happy Path: encrypts and decrypts successfully', () {
      const originalText = 'Sovereign vault integration test payload';

      final ciphertext = vaultCryptoService.encryptData(
        originalText,
        validTestKeyHex,
      );

      expect(ciphertext, isNotEmpty);
      expect(ciphertext, isNot(originalText));

      final decryptedText = vaultCryptoService.decryptData(
        ciphertext,
        validTestKeyHex,
      );

      expect(decryptedText, equals(originalText));
    });

    test('Tamper Protocol: throws when ciphertext is modified', () {
      const originalText = 'Tamper detection payload';

      final ciphertext = vaultCryptoService.encryptData(
        originalText,
        validTestKeyHex,
      );

      final lastChar = ciphertext[ciphertext.length - 1];
      final replacementChar = lastChar == 'A' ? 'B' : 'A';
      final tamperedCiphertext =
          ciphertext.replaceRange(ciphertext.length - 1, ciphertext.length, replacementChar);

      expect(
        () => vaultCryptoService.decryptData(tamperedCiphertext, validTestKeyHex),
        throwsA(isA<Exception>()),
      );
    });

    test('Bad Key: throws when key is not 64 hex characters', () {
      const originalText = 'Invalid key length payload';
      const invalidKeyHex =
          '0123456789abcdef0123456789abcdef0123456789abcdef0123456789ab';

      expect(
        () => vaultCryptoService.encryptData(originalText, invalidKeyHex),
        throwsA(isA<Exception>()),
      );
    });
  });
}
