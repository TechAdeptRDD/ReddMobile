import 'package:flutter_test/flutter_test.dart';
import 'package:redd_mobile/bloc/dashboard/dashboard_bloc.dart';
import 'package:redd_mobile/bloc/dashboard/dashboard_event.dart';
import 'package:redd_mobile/bloc/dashboard/dashboard_state.dart';
import 'package:redd_mobile/services/vault_crypto_service.dart';
import 'package:redd_mobile/services/blockbook_service.dart';

class FakeVaultCryptoService extends VaultCryptoService {
  @override
  String generateOpReturnPayload(String command, String identifier) => "MOCK_PAYLOAD";
  
  @override
  String signOpReturnTransaction({
    required String privateKeyHex, required String utxoTxid, required int utxoVout,
    required int utxoAmount, required String opReturnPayload, required String changeAddress,
    required int networkFee,
  }) {
    return "SIGNED_TX_FOR_$utxoTxid";
  }
}

class FakeBlockbookService extends BlockbookService {
  @override
  Future<List<Utxo>> getUtxos(String address) async {
    return [Utxo(txid: '12345abcde', vout: 0, value: '5000000000', confirmations: 10)];
  }
}

void main() {
  test('AcquireReddIDEvent triggers full UTXO fetch and Tx Signing flow', () async {
    final bloc = DashboardBloc(
      vaultCryptoService: FakeVaultCryptoService(),
      blockbookService: FakeBlockbookService(),
    );

    bloc.add(AcquireReddIDEvent('techadept.redd'));

    await expectLater(
      bloc.stream,
      emitsInOrder([
        isA<DashboardLoading>(),
        isA<ReddIDPayloadGenerated>().having((s) => s.payloadHex, 'hex', 'SIGNED_TX_FOR_12345abcde'),
      ]),
    );
    bloc.close();
  });
}
