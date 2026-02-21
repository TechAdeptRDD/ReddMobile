import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/blockbook_service.dart';
import '../../services/secure_storage_service.dart';
import '../../services/vault_crypto_service.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

// --- Bloc ---
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final BlockbookService blockbook;
  final SecureStorageService storage;
  final VaultCryptoService vault;
  final http.Client? httpClient;
  static const Duration _fiatRequestTimeout = Duration(seconds: 6);
  int _activeLoadId = 0;

  DashboardBloc({
    BlockbookService? blockbookService,
    SecureStorageService? storageService,
    VaultCryptoService? vaultCryptoService,
    http.Client? httpClient,
  })  : blockbook = blockbookService ?? BlockbookService(),
        storage = storageService ?? SecureStorageService(),
        vault = vaultCryptoService ?? VaultCryptoService(),
        httpClient = httpClient ?? http.Client(),
        super(DashboardInitial()) {
    on<LoadDashboardData>((event, emit) async {
      emit(DashboardLoading());
      // Monotonic load ids guard against out-of-order async completions overwriting
      // newer state with stale network responses.
      final loadId = ++_activeLoadId;
      try {
        final mnemonic = await storage.getMnemonic();
        if (mnemonic == null) {
          emit(DashboardError("Wallet not found."));
          return;
        }
        final address = vault.deriveReddcoinAddress(mnemonic);

        final data = await blockbook.getAddressDetails(address);
        final balanceSats = (int.tryParse('${data['balance'] ?? '0'}') ?? 0) +
            (int.tryParse('${data['unconfirmedBalance'] ?? '0'}') ?? 0);
        final balanceRdd = balanceSats / 100000000;

        String formatted = balanceRdd.toStringAsFixed(2).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

        // Fetch live fiat price with selected currency preference.
        double fiatPrice = 0.0;
        final preferredCurrency =
            (await storage.getFiatPreference()).toLowerCase().trim();
        try {
          final res = await httpClient
              ?.get(
                Uri.parse(
                  'https://api.coingecko.com/api/v3/simple/price?ids=reddcoin&vs_currencies=$preferredCurrency',
                ),
              )
              .timeout(_fiatRequestTimeout);
          if (res?.statusCode == 200) {
            final decoded = json.decode(res!.body) as Map<String, dynamic>;
            final reddcoin = decoded['reddcoin'] as Map<String, dynamic>?;
            final rawPrice = reddcoin?[preferredCurrency];
            if (rawPrice is num) {
              fiatPrice = rawPrice.toDouble();
            }
          }
        } catch (_) {
          /* Silently fail fiat fetch to keep core wallet functional */
        }

        final double totalFiat = balanceRdd * fiatPrice;
        final String formattedFiat =
            "${totalFiat.toStringAsFixed(2)} ${preferredCurrency.toUpperCase()}";

        final List<dynamic> txs = data['transactions'] ?? [];
        if (loadId == _activeLoadId) {
          emit(DashboardLoaded(address, formatted, formattedFiat, txs));
        }
      } catch (e) {
        // Keep error text intentionally generic to avoid leaking low-level parsing/network
        // details into user-facing UI, while still signaling sync failure.
        if (loadId == _activeLoadId) {
          emit(const DashboardError("Failed to sync wallet data."));
        }
      }
    }, transformer: restartable());

    on<AcquireReddIDEvent>((event, emit) {
      emit(const ReddIDPayloadGenerated(''));
    }, transformer: restartable());

  }

  @override
  Future<void> close() {
    httpClient?.close();
    return super.close();
  }
}
