import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:redd_mobile/bloc/dashboard/dashboard_bloc.dart';
import 'package:redd_mobile/services/blockbook_service.dart';
import 'package:redd_mobile/services/secure_storage_service.dart';
import 'package:redd_mobile/services/vault_crypto_service.dart';

class _FakeBlockbookService extends BlockbookService {
  _FakeBlockbookService(this.payload);

  final Map<String, dynamic> payload;

  @override
  Future<Map<String, dynamic>> getAddressDetails(String address) async => payload;
}

class _FakeSecureStorageService extends SecureStorageService {
  _FakeSecureStorageService({this.mnemonic, this.currency = 'usd'});

  final String? mnemonic;
  final String currency;

  @override
  Future<String?> getMnemonic() async => mnemonic;

  @override
  Future<String> getFiatPreference() async => currency;
}

class _FakeVaultCryptoService extends VaultCryptoService {
  @override
  String deriveReddcoinAddress(String mnemonic) => 'RTestAddress123';
}

void main() {
  group('DashboardBloc QA critical flows', () {
    test('emits error when wallet mnemonic is missing', () async {
      final bloc = DashboardBloc(
        blockbookService: _FakeBlockbookService({}),
        storageService: _FakeSecureStorageService(mnemonic: null),
        vaultCryptoService: _FakeVaultCryptoService(),
      );

      bloc.add(LoadDashboardData());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<DashboardLoading>(),
          isA<DashboardError>().having((s) => s.message, 'message', 'Wallet not found.'),
        ]),
      );
      await bloc.close();
    });

    test('loads balance, history, and fiat conversion successfully', () async {
      final bloc = DashboardBloc(
        blockbookService: _FakeBlockbookService({
          'balance': '250000000',
          'unconfirmedBalance': '50000000',
          'transactions': ['tx1', 'tx2'],
        }),
        storageService: _FakeSecureStorageService(mnemonic: 'seed words', currency: 'eur'),
        vaultCryptoService: _FakeVaultCryptoService(),
        httpClient: MockClient((request) async {
          expect(request.url.toString(), contains('vs_currencies=eur'));
          return http.Response(jsonEncode({'reddcoin': {'eur': 0.1}}), 200);
        }),
      );

      bloc.add(LoadDashboardData());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<DashboardLoading>(),
          isA<DashboardLoaded>()
              .having((s) => s.address, 'address', 'RTestAddress123')
              .having((s) => s.formattedBalance, 'formattedBalance', '3.00')
              .having((s) => s.fiatValue, 'fiatValue', '0.30 EUR')
              .having((s) => s.history.length, 'history length', 2),
        ]),
      );
      await bloc.close();
    });

    test('continues with zero fiat value when price API fails', () async {
      final bloc = DashboardBloc(
        blockbookService: _FakeBlockbookService({
          'balance': '150000000',
          'unconfirmedBalance': '0',
          'transactions': [],
        }),
        storageService: _FakeSecureStorageService(mnemonic: 'seed words', currency: 'usd'),
        vaultCryptoService: _FakeVaultCryptoService(),
        httpClient: MockClient((request) async => http.Response('upstream error', 500)),
      );

      bloc.add(LoadDashboardData());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<DashboardLoading>(),
          isA<DashboardLoaded>().having((s) => s.fiatValue, 'fiatValue', '0.00 USD'),
        ]),
      );
      await bloc.close();
    });
  });
}
