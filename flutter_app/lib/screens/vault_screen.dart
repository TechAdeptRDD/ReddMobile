import 'package:flutter/material.dart';
import '../services/vault_crypto_service.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const String appVersion =
        String.fromEnvironment('APP_VERSION', defaultValue: 'v0.2.0-Alpha');
    final vaultService = VaultCryptoService();

    void showMnemonicDialog() {
      // Call Rust to generate the phrase
      final mnemonic = vaultService.generateNewMnemonic();

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text("New Wallet Generated",
              style: TextStyle(color: Color(0xFFE31B23))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Write this down safely:",
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 15),
              SelectableText(
                mnemonic,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("I have saved it"),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/branding/redd_logo_full.png', height: 120),
                const SizedBox(height: 40),
                const Text("SECURE VAULT",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4)),
                const SizedBox(height: 60),

                // Existing Unlock Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE31B23),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/dashboard'),
                  child: const Text("UNLOCK WALLET",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),

                const SizedBox(height: 20),

                // NEW: Create Wallet Button
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE31B23)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                  onPressed: showMnemonicDialog,
                  child: const Text("CREATE NEW WALLET",
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text("ReddMobile $appVersion",
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.3), fontSize: 10)),
            ),
          ),
        ],
      ),
    );
  }
}
