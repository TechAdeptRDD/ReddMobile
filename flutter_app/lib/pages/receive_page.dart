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
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("Receive RDD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // The VIP ReddCard
                Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE31B23), Color(0xFF5A080C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFFE31B23).withOpacity(0.4), blurRadius: 30, spreadRadius: 5, offset: const Offset(0, 15))
                    ],
                    border: Border.all(color: Colors.white24, width: 1),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.account_balance_wallet, color: Colors.white70, size: 30),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                            child: const Text("ReddMobile VIP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: QrImageView(data: address, version: QrVersions.auto, size: 180.0),
                      ),
                      const SizedBox(height: 30),
                      const Text("NETWORK ADDRESS", style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2)),
                      const SizedBox(height: 8),
                      Text(
                        "${address.substring(0, 12)}...${address.substring(address.length - 8)}",
                        style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Haptic Copy Button
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE31B23), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      backgroundColor: const Color(0xFFE31B23).withOpacity(0.1),
                    ),
                    onPressed: () {
                      HapticFeedback.heavyImpact(); // Physical device vibration!
                      Clipboard.setData(ClipboardData(text: address));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 10), Text("Address copied to clipboard!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]), 
                          backgroundColor: Color(0xFFE31B23),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy, color: Colors.white),
                    label: const Text("COPY ADDRESS", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
