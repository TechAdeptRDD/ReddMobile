import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'screens/vault_screen.dart';
import 'screens/dashboard_screen.dart';
import 'bloc/dashboard/dashboard_bloc.dart';
import 'bloc/activity/activity_bloc.dart';
import 'services/vault_crypto_service.dart';
import 'services/blockbook_service.dart';

void main() {
  // Initialize services
  final vaultService = VaultCryptoService();
  final blockbookService = BlockbookService();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<DashboardBloc>(
          create: (context) => DashboardBloc(
            vaultCryptoService: vaultService,
            blockbookService: blockbookService,
          ),
        ),
        BlocProvider<ActivityBloc>(
          create: (context) => ActivityBloc(
            blockbookService: blockbookService,
          ),
        ),
      ],
      child: const ReddMobileApp(),
    ),
  );
}

class ReddMobileApp extends StatelessWidget {
  const ReddMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ReddMobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFE31B23),
        scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const VaultScreen(),
        '/dashboard': (context) => const MainShell(),
      },
    );
  }
}
