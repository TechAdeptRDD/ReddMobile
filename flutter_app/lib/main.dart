import 'package:flutter/material.dart';
import 'screens/vault_screen.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const ReddMobileApp());
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
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}
