import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../services/vault_crypto_service.dart';

abstract class VaultEvent {}

class CheckVaultStatus extends VaultEvent {}

class UnlockVaultRequested extends VaultEvent {
  final String password;

  UnlockVaultRequested(this.password);
}

abstract class VaultState {}

class VaultLocked extends VaultState {}

class VaultUnlocking extends VaultState {}

class VaultSetupRequired extends VaultState {}

class VaultUnlocked extends VaultState {
  final String decryptedKey;

  VaultUnlocked(this.decryptedKey);
}

class VaultError extends VaultState {
  final String message;

  VaultError(this.message);
}

class VaultBloc extends Bloc<VaultEvent, VaultState> {
  static const String _encryptedMnemonicKey = 'encrypted_mnemonic';

  final VaultCryptoService cryptoService;
  final FlutterSecureStorage secureStorage;

  VaultBloc({
    required this.cryptoService,
    FlutterSecureStorage? secureStorage,
  })  : secureStorage = secureStorage ?? const FlutterSecureStorage(),
        super(VaultLocked()) {
    on<CheckVaultStatus>(_onCheckVaultStatus);
    on<UnlockVaultRequested>(_onUnlockVaultRequested);

    add(CheckVaultStatus());
  }

  Future<void> _onCheckVaultStatus(
    CheckVaultStatus event,
    Emitter<VaultState> emit,
  ) async {
    try {
      final encryptedMnemonic =
          await secureStorage.read(key: _encryptedMnemonicKey);

      if (encryptedMnemonic == null || encryptedMnemonic.isEmpty) {
        emit(VaultSetupRequired());
      } else {
        emit(VaultLocked());
      }
    } catch (_) {
      emit(VaultSetupRequired());
    }
  }

  Future<void> _onUnlockVaultRequested(
    UnlockVaultRequested event,
    Emitter<VaultState> emit,
  ) async {
    emit(VaultUnlocking());

    try {
      final encryptedMnemonic =
          await secureStorage.read(key: _encryptedMnemonicKey);

      if (encryptedMnemonic == null || encryptedMnemonic.isEmpty) {
        emit(VaultSetupRequired());
        return;
      }

      final decryptedKey =
          cryptoService.decryptData(encryptedMnemonic, event.password);

      if (decryptedKey.isEmpty || decryptedKey.contains('ERROR')) {
        emit(VaultError('Invalid PIN/Password.'));
        return;
      }

      emit(VaultUnlocked(decryptedKey));
    } catch (_) {
      emit(VaultError('Invalid PIN/Password.'));
    }
  }
}
