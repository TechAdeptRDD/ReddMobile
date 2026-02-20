import 'package:flutter/material.dart';
import '../services/vault_crypto_service.dart';
import '../services/secure_storage_service.dart';
import '../main.dart';
import 'backup_phrase_page.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  final _vault = VaultCryptoService();
  final _storage = SecureStorageService();
  bool _isProcessing = false;

  Future<void> _createNewWallet() async {
    setState(() => _isProcessing = true);
    final mnemonic = _vault.generateMnemonic();

    if (mounted) {
      // Secure Flow: Route to Backup screen instead of saving instantly
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => BackupPhrasePage(mnemonic: mnemonic)),
      );
    }
  }

  void _importWallet() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        title:
            const Text("Import Wallet", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
              hintText: "Enter 12 or 24 word seed phrase...",
              hintStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.black26,
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(15))),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  const Text("CANCEL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE31B23)),
            onPressed: () async {
              if (controller.text.trim().split(" ").length >= 12) {
                await _storage.saveMnemonic(controller.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MainNavigation()));
                }
              }
            },
            child: const Text("IMPORT", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const Icon(Icons.account_balance_wallet,
                  size: 100, color: Color(0xFFE31B23)),
              const SizedBox(height: 30),
              const Text("ReddMobile",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("The Decentralized Social Wallet",
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
              const Spacer(),
              if (_isProcessing)
                const CircularProgressIndicator(color: Color(0xFFE31B23))
              else ...[
                SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE31B23),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15))),
                        onPressed: _createNewWallet,
                        child: const Text("CREATE NEW WALLET",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)))),
                const SizedBox(height: 20),
                SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                                color: Color(0xFFE31B23), width: 2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15))),
                        onPressed: _importWallet,
                        child: const Text("IMPORT EXISTING",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)))),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
