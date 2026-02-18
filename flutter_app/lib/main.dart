import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'services/vault_crypto_service.dart';
import 'services/blockbook_service.dart';
import 'bloc/vault/vault_bloc.dart';
import 'bloc/dashboard/dashboard_bloc.dart';
import 'screens/vault_screen.dart';
import 'package:redd_mobile/screens/dashboard_screen.dart'; // We will ensure this exists next

void main() {
  runApp(const ReddMobileApp());
}

class ReddMobileApp extends StatelessWidget {
  const ReddMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (context) => VaultCryptoService()),
        RepositoryProvider(create: (context) => BlockbookService()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => VaultBloc(
              cryptoService: RepositoryProvider.of<VaultCryptoService>(context),
            ),
          ),
          BlocProvider(
            create: (context) => DashboardBloc(
              vaultCryptoService: RepositoryProvider.of<VaultCryptoService>(context),
              blockbookService: RepositoryProvider.of<BlockbookService>(context),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'ReddMobile',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(brightness: Brightness.dark, primaryColor: const Color(0xFFE31B23)),
          initialRoute: '/',
          routes: {
            '/': (context) => VaultScreen(),
            '/dashboard': (context) => const DashboardScreen(),
          },
        ),
      ),
    );
  }
}

// Minimal Dashboard placeholder for navigation test
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("REDDMOBILE DASHBOARD")),
      body: const Center(child: Text("Welcome to the Secure Layer")),
    );
  }
}
