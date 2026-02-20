import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../services/blockbook_service.dart';
import '../../services/secure_storage_service.dart';
import '../../services/vault_crypto_service.dart';

// --- Events ---
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object> get props => [];
}

class LoadDashboardData extends DashboardEvent {}

// --- States ---
abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final String address;
  final String formattedBalance;
  final String fiatValue;
  final List<dynamic> history;

  const DashboardLoaded(
      this.address, this.formattedBalance, this.fiatValue, this.history);
  @override
  List<Object> get props => [address, formattedBalance, fiatValue, history];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError(this.message);
  @override
  List<Object> get props => [message];
}

// --- Bloc ---
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final BlockbookService blockbook = BlockbookService();
  final SecureStorageService storage = SecureStorageService();
  final VaultCryptoService vault = VaultCryptoService();

  DashboardBloc() : super(DashboardInitial()) {
    on<LoadDashboardData>((event, emit) async {
      emit(DashboardLoading());
      try {
        final mnemonic = await storage.getMnemonic();
        if (mnemonic == null) {
          emit(const DashboardError("Wallet not found."));
          return;
        }
        final address = vault.deriveReddcoinAddress(mnemonic);

        final data = await blockbook.getAddressDetails(address);
        final balanceSats = int.parse(data['balance'] ?? '0') +
            int.parse(data['unconfirmedBalance'] ?? '0');
        final balanceRdd = balanceSats / 100000000;

        String formatted = balanceRdd.toStringAsFixed(2).replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');

        // Fetch Live Fiat Price (USD)
        double fiatPrice = 0.0;
        try {
          final preferredCurrency = await storage.getFiatPreference();
          final res = await http.get(Uri.parse(
              "https://api.coingecko.com/api/v3/simple/price?ids=reddcoinfinal res = await http.get(Uri.parse('https://api.coingecko.com/api/v3/simple/price?ids=reddcoin&vs_currencies=usd'));vs_currencies=$preferredCurrency"));
          if (res.statusCode == 200) {
            fiatPrice = (json.decode(res.body)["reddcoin"][preferredCurrency] as num)
                .toDouble();
          }
        } catch (_) {
          /* Silently fail fiat fetch to keep core wallet functional */
        }

        final double totalFiat = balanceRdd * fiatPrice;
        String formattedFiat =
            "${totalFiat.toStringAsFixed(2)} ${"USD"}";

        final List<dynamic> txs = data['transactions'] ?? [];
        emit(DashboardLoaded(address, formatted, formattedFiat, txs));
      } catch (e) {
        emit(DashboardError("Failed to sync wallet data."));
      }
    });
  }
}
