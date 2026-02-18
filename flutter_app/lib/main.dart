import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:redd_mobile/services/blockbook_service.dart';
import 'package:redd_mobile/services/vault_crypto_service.dart';
import 'package:redd_mobile/bloc/onboarding/onboarding_bloc.dart';
import 'package:redd_mobile/ui/screens/onboarding_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
            create: (context) => OnboardingBloc(
              blockbookService: RepositoryProvider.of<BlockbookService>(context),
              vaultCryptoService:
                  RepositoryProvider.of<VaultCryptoService>(context),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'ReddMobile',
          themeMode: ThemeMode.dark,
          theme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFB71C1C),
              brightness: Brightness.dark,
            ),
          ),
          home: const OnboardingScreen(),
        ),
      ),
    );
  }
}