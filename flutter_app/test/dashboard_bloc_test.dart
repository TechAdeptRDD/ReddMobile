import 'package:flutter_test/flutter_test.dart';
import 'package:redd_mobile/bloc/dashboard/dashboard_bloc.dart';
import 'package:redd_mobile/bloc/dashboard/dashboard_event.dart';
import 'package:redd_mobile/bloc/dashboard/dashboard_state.dart';
import 'package:redd_mobile/services/vault_crypto_service.dart';
import 'package:redd_mobile/services/blockbook_service.dart';

class FakeBlockbookService extends BlockbookService {
  @override
  Future<List<dynamic>> getUtxos(String address) async {
    return [
      {'txid': '12345abcde', 'vout': 0, 'value': '500000000'}
    ];
  }
}

void main() {
  test('DashboardBloc emits Success when Rust signs multi-input tx', () async {
    final bloc = DashboardBloc(
      vaultCryptoService: VaultCryptoService(),
      blockbookService: FakeBlockbookService(),
    );

    bloc.add(AcquireReddIDEvent("techadept"));

    await expectLater(
      bloc.stream,
      emitsInOrder([
        isA<DashboardLoading>(),
        isA<ReddIDPayloadGenerated>(),
      ]),
    );
  });
}
