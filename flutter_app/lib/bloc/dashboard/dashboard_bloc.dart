import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/vault_crypto_service.dart';
import '../../services/blockbook_service.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final VaultCryptoService vaultCryptoService;
  final BlockbookService blockbookService;

  DashboardBloc({
    required this.vaultCryptoService,
    required this.blockbookService,
  }) : super(DashboardInitial()) {
    
    on<AcquireReddIDEvent>((event, emit) async {
      emit(DashboardLoading());
      
      try {
        // 1. Fetch UTXOs from the network (using the official dev fund address for testing)
        final utxos = await blockbookService.getUtxos('Rmhzj1f9DmyzQnXZKnrXz4F2J2rMrcNf6K');
        
        if (utxos.isEmpty) {
          emit(DashboardError("No UTXOs found. Please fund your wallet."));
          return;
        }

        // 2. Pick the first UTXO (In a real app, you'd calculate the optimal UTXOs to spend)
        final selectedUtxo = utxos.first;
        final utxoAmount = int.tryParse(selectedUtxo.value) ?? 0;

        // 3. Generate the OP_RETURN Payload via Rust FFI
        final payloadHex = vaultCryptoService.generateOpReturnPayload("nsbid", event.handle);
        
        // 4. Sign the raw transaction via Rust FFI
        // Note: Using dummy keys and change addresses for this architectural mock
        final signedTxHex = vaultCryptoService.signOpReturnTransaction(
          privateKeyHex: "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
          utxoTxid: selectedUtxo.txid,
          utxoVout: selectedUtxo.vout,
          utxoAmount: utxoAmount,
          opReturnPayload: payloadHex,
          changeAddress: "Rmhzj1f9DmyzQnXZKnrXz4F2J2rMrcNf6K",
          networkFee: 1000000, // 0.01 RDD fee in Satoshis
        );
        
        // 5. Success! Emit the signed transaction ready for broadcast
        emit(ReddIDPayloadGenerated(signedTxHex));
        
      } catch (e) {
        emit(DashboardError("Transaction failed: $e"));
      }
    });
  }
}
