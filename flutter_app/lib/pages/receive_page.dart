import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/secure_storage_service.dart';
import '../services/vault_crypto_service.dart';

class ReceivePage extends StatelessWidget {
  const ReceivePage({super.key});

  @override
  Widget build(BuildContext context) {
    final SecureStorageService storage = SecureStorageService();
    final VaultCryptoService vault = VaultCryptoService();

    return Scaffold(
      backgroundColor: const Color(0xFF151515),
      appBar: AppBar(
        title: const Text("Receive RDD", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<String?>(
        future: storage.getMnemonic(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFE31B23)));
          
          final address = vault.deriveReddcoinAddress(snapshot.data!);

          return Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Your Public Address",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 20),
                
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: QrImageView(
                    data: address,
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ),
                
                const SizedBox(height: 30),
                
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: address));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Address copied to clipboard!", style: TextStyle(color: Colors.white)), backgroundColor: Color(0xFFE31B23)),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: const Color(0xFFE31B23), width: 1),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            address,
                            style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const Icon(Icons.copy, color: Colors.grey, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Tap to copy",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
