import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/vault_crypto_service.dart';
import '../../services/blockbook_service.dart';
import '../../models/utxo.dart';
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
        final rawUtxos = await blockbookService.getUtxos('Rmhzj1f9DmyzQnXZKnrXz4F2J2rMrcNf6K');
        final utxos = rawUtxos.map((json) => Utxo.fromJson(json)).toList();

        if (utxos.isEmpty) {
          emit(DashboardError("No UTXOs found."));
          return;
        }

        final signedTxHex = vaultCryptoService.signMultiInputTransaction(
          utxos: utxos.map((u) => u.toJson()).toList(),
          privateKeyHex: "deadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeefdeadbeef",
          opReturnData: "nsbid:${event.handle}",
          changeAddress: "Rmhzj1f9DmyzQnXZKnrXz4F2J2rMrcNf6K",
          feePerKb: 1000,
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
