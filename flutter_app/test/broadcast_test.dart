import 'package:flutter_test/flutter_test.dart';
import 'package:redd_mobile/bloc/dashboard/dashboard_bloc.dart';
import 'package:redd_mobile/bloc/dashboard/dashboard_event.dart';
import 'package:redd_mobile/bloc/dashboard/dashboard_state.dart';
import 'package:redd_mobile/services/vault_crypto_service.dart';
import 'package:redd_mobile/services/blockbook_service.dart';

class MockBlockbook extends BlockbookService {
  @override
  Future<String> broadcastTransaction(String hex) async => "TXID_12345_CONFIRMED";
}

void main() {
  test('BroadcastTransactionEvent results in success state with TXID', () async {
    final bloc = DashboardBloc(
      vaultCryptoService: VaultCryptoService(), 
      blockbookService: MockBlockbook()
    );

    bloc.add(BroadcastTransactionEvent("01000000..."));

    await expectLater(
      bloc.stream,
      emitsInOrder([
        isA<DashboardLoading>(),
        isA<TransactionBroadcastSuccess>().having((s) => s.txid, 'txid', 'TXID_12345_CONFIRMED'),
      ]),
    );
  });
}
