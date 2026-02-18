import 'package:flutter_test/flutter_test.dart';
import 'package:redd_mobile/bloc/dashboard/dashboard_bloc.dart';
import 'package:redd_mobile/bloc/dashboard/dashboard_event.dart';
import 'package:redd_mobile/bloc/dashboard/dashboard_state.dart';
import 'package:redd_mobile/services/vault_crypto_service.dart';

class FakeVaultCryptoService extends VaultCryptoService {
  @override
  String generateOpReturnPayload(String command, String identifier) {
    return "TERMINAL_TEST_PAYLOAD_${command.toUpperCase()}_${identifier.toUpperCase()}";
  }
}

void main() {
  group('DashboardBloc Architecture Tests', () {
    late DashboardBloc dashboardBloc;
    late FakeVaultCryptoService fakeCryptoService;

    setUp(() {
      fakeCryptoService = FakeVaultCryptoService();
      dashboardBloc = DashboardBloc(vaultCryptoService: fakeCryptoService);
    });

    tearDown(() {
      dashboardBloc.close();
    });

    test('1. Initial state must be DashboardInitial', () {
      expect(dashboardBloc.state is DashboardInitial, true);
    });

    test('2. AcquireReddIDEvent must emit Loading, then PayloadGenerated', () async {
      dashboardBloc.add(AcquireReddIDEvent('techadept.redd'));

      await expectLater(
        dashboardBloc.stream,
        emitsInOrder([
          isA<DashboardLoading>(),
          isA<ReddIDPayloadGenerated>().having(
            (state) => state.payloadHex,
            'payloadHex',
            'TERMINAL_TEST_PAYLOAD_NSBID_TECHADEPT.REDD',
          ),
        ]),
      );
    });
  });
}
