import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/activity_feed.dart';
import '../widgets/send_dialog.dart';
import '../services/vault_crypto_service.dart';
import '../services/secure_storage_service.dart';

class WalletTab extends StatefulWidget {
  const WalletTab({super.key});

  @override
  State<WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<WalletTab> {
  String _reddcoinAddress = "Loading...";

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    final storage = SecureStorageService();
    final vault = VaultCryptoService();
    
    final mnemonic = await storage.getMnemonic();
    if (mnemonic != null) {
      final address = vault.deriveReddcoinAddress(mnemonic);
      setState(() => _reddcoinAddress = address);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Image.asset('assets/branding/redd_logo_dark.png', height: 28),
        actions: [
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFFE31B23)), 
            onPressed: () => showModalBottomSheet(
                context: context, 
                isScrollControlled: true, 
                backgroundColor: Colors.transparent, 
                builder: (context) => const SendDialog()
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Text("0.00 RDD", style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          
          // Address Display Pill
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: _reddcoinAddress));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Address copied to clipboard!")));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.qr_code_2, color: Colors.grey, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _reddcoinAddress.length > 15 ? "${_reddcoinAddress.substring(0, 8)}...${_reddcoinAddress.substring(_reddcoinAddress.length - 8)}" : _reddcoinAddress, 
                    style: const TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1)
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.copy, color: Colors.grey, size: 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Expanded(child: ActivityFeed()),
        ],
      ),
    );
  }
}
