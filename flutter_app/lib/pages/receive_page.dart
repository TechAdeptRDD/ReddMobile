import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/secure_storage_service.dart';
import '../services/vault_crypto_service.dart';

class ReceivePage extends StatefulWidget {
  const ReceivePage({super.key});

  @override
  State<ReceivePage> createState() => _ReceivePageState();
}

class _ReceivePageState extends State<ReceivePage> {
  final SecureStorageService storage = SecureStorageService();
  final VaultCryptoService vault = VaultCryptoService();
  final ScreenshotController _screenshotController = ScreenshotController();
  
  bool _isExporting = false;

  void _exportAndShareCard() async {
    setState(() => _isExporting = true);
    HapticFeedback.heavyImpact();
    
    try {
      final Uint8List? image = await _screenshotController.capture(delay: const Duration(milliseconds: 10));
      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final imagePath = await File('${directory.path}/ReddCard.png').create();
        await imagePath.writeAsBytes(image);
        
        await Share.shareXFiles(
          [XFile(imagePath.path)], 
          text: "Drop me a tip on the ReddCoin Network! 🚀\\nDownload ReddMobile to send RDD instantly."
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error exporting card.")));
    }
    
    setState(() => _isExporting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(title: const Text("Receive RDD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
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
                // The Exportable Capture Boundary
                Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFE31B23), Color(0xFF5A080C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: const Color(0xFFE31B23).withOpacity(0.4), blurRadius: 30, spreadRadius: 5, offset: const Offset(0, 15))],
                      border: Border.all(color: Colors.white24, width: 1),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Icon(Icons.account_balance_wallet, color: Colors.white70, size: 30),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)), child: const Text("ReddMobile VIP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1))),
                          ],
                        ),
                        const SizedBox(height: 30),
                        Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)), child: QrImageView(data: address, version: QrVersions.auto, size: 180.0)),
                        const SizedBox(height: 30),
                        const Text("NETWORK ADDRESS", style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2)),
                        const SizedBox(height: 8),
                        Text("${address.substring(0, 12)}...${address.substring(address.length - 8)}", style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // Export to Socials Button
                SizedBox(
                  width: double.infinity, height: 60,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE31B23), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    onPressed: _isExporting ? null : _exportAndShareCard,
                    icon: _isExporting ? const SizedBox.shrink() : const Icon(Icons.ios_share, color: Colors.white),
                    label: _isExporting ? const CircularProgressIndicator(color: Colors.white) : const Text("SHARE TO SOCIALS", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 15),
                TextButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Clipboard.setData(ClipboardData(text: address));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Address copied to clipboard!"), backgroundColor: Color(0xFFE31B23)));
                  },
                  icon: const Icon(Icons.copy, color: Colors.grey),
                  label: const Text("Copy Raw Address", style: TextStyle(color: Colors.grey)),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
