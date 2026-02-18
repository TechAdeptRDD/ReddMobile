import 'package:flutter_test/flutter_test.dart';
import 'package:redd_mobile/bloc/vault/vault_bloc.dart';
import 'package:redd_mobile/services/vault_crypto_service.dart';

void main() {
  test('VaultBloc should unlock when Rust FFI confirms valid decryption', () async {
    final cryptoService = VaultCryptoService();
    final vaultBloc = VaultBloc(cryptoService: cryptoService);

    vaultBloc.add(UnlockVaultRequested("1234"));

    await expectLater(
      vaultBloc.stream,
      emitsInOrder([
        isA<VaultUnlocking>(),
        isA<VaultUnlocked>(),
      ]),
    );
  });
}
