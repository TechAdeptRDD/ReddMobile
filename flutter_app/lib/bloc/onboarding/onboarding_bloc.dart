import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:redd_mobile/bloc/onboarding/onboarding_event.dart';
import 'package:redd_mobile/bloc/onboarding/onboarding_state.dart';
import 'package:redd_mobile/services/blockbook_service.dart';
import 'package:redd_mobile/services/vault_crypto_service.dart';

class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  OnboardingBloc({
    required BlockbookService blockbookService,
    required VaultCryptoService vaultCryptoService,
  })  : _blockbookService = blockbookService,
        _vaultCryptoService = vaultCryptoService,
        super(OnboardingInitial()) {
    on<CheckHandle>(_onCheckHandle);
    on<ClaimHandleAndCreateWallet>(_onClaimHandleAndCreateWallet);
  }

  final BlockbookService _blockbookService;
  final VaultCryptoService _vaultCryptoService;

  static const String _dummyKeyHex =
      '0000000000000000000000000000000000000000000000000000000000000000';

  Future<void> _onCheckHandle(
    CheckHandle event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(HandleChecking());

    // Placeholder for upcoming Blockbook API integration.
    _blockbookService.hashCode;

    await Future<void>.delayed(const Duration(seconds: 1));
    emit(HandleAvailable());
  }

  Future<void> _onClaimHandleAndCreateWallet(
    ClaimHandleAndCreateWallet event,
    Emitter<OnboardingState> emit,
  ) async {
    emit(WalletCreating());

    try {
      _vaultCryptoService.encryptData('SetupComplete', _dummyKeyHex);
      emit(OnboardingComplete());
    } catch (error) {
      emit(OnboardingError(error.toString()));
    }
  }
}
