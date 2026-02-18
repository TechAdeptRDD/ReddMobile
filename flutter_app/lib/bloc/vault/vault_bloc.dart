import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/vault_crypto_service.dart';

abstract class VaultEvent {}
class UnlockVaultRequested extends VaultEvent {
  final String password;
  UnlockVaultRequested(this.password);
}

abstract class VaultState {}
class VaultLocked extends VaultState {}
class VaultUnlocking extends VaultState {}
class VaultUnlocked extends VaultState {
  final String decryptedKey;
  VaultUnlocked(this.decryptedKey);
}
class VaultError extends VaultState {
  final String message;
  VaultError(this.message);
}

class VaultBloc extends Bloc<VaultEvent, VaultState> {
  final VaultCryptoService cryptoService;

  VaultBloc({required this.cryptoService}) : super(VaultLocked()) {
    on<UnlockVaultRequested>((event, emit) async {
      emit(VaultUnlocking());
      
      await Future.delayed(const Duration(milliseconds: 800));

      try {
        const mockEncryptedBlob = "REDD_ENCRYPTED_DATA_V1"; 
        final result = cryptoService.decryptData(mockEncryptedBlob, event.password);
        
        if (result.contains("ERROR")) {
          emit(VaultError("Invalid PIN/Password."));
        } else {
          emit(VaultUnlocked(result));
        }
      } catch (e) {
        emit(VaultError("Vault Access Denied: $e"));
      }
    });
  }
}
