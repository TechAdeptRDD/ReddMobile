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
        final utxos = await blockbookService.getUtxos('Rmhzj1f9DmyzQnXZKnrXz4F2J2rMrcNf6K');
        if (utxos.isEmpty) {
          emit(DashboardError("No UTXOs found. Please fund your wallet."));
          return;
        }
        final selectedUtxo = utxos.first;
        final utxoAmount = int.tryParse(selectedUtxo.value) ?? 0;
        final payloadHex = vaultCryptoService.generateOpReturnPayload("nsbid", event.handle);
        
        final signedTxHex = vaultCryptoService.signOpReturnTransaction(
          privateKeyHex: "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
          utxoTxid: selectedUtxo.txid,
          utxoVout: selectedUtxo.vout,
          utxoAmount: utxoAmount,
          opReturnPayload: payloadHex,
          changeAddress: "Rmhzj1f9DmyzQnXZKnrXz4F2J2rMrcNf6K",
          networkFee: 1000000,
        );
        
        emit(ReddIDPayloadGenerated(signedTxHex));
      } catch (e) {
        emit(DashboardError("Signing failed: $e"));
      }
    });

    on<BroadcastTransactionEvent>((event, emit) async {
      emit(DashboardLoading());
      try {
        final txid = await blockbookService.broadcastTransaction(event.signedTxHex);
        emit(TransactionBroadcastSuccess(txid));
      } catch (e) {
        emit(DashboardError("Broadcast failed: $e"));
      }
    });
  }
}
