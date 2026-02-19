import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/activity_feed.dart';
import '../widgets/send_dialog.dart';
import '../services/vault_crypto_service.dart';
import '../services/secure_storage_service.dart';
import '../services/blockbook_service.dart';

class WalletTab extends StatefulWidget {
  const WalletTab({super.key});

  @override
  State<WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<WalletTab> {
  String _reddcoinAddress = "Loading...";
  double _balanceRdd = 0.0;
  double _fiatValueUsd = 0.0;
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  final BlockbookService _networkService = BlockbookService();

  @override
  void initState() {
    super.initState();
    _initializeWallet();
  }

  Future<void> _initializeWallet() async {
    final storage = SecureStorageService();
    final vault = VaultCryptoService();
    
    final mnemonic = await storage.getMnemonic();
    if (mnemonic != null && mnemonic.isNotEmpty) {
      final address = vault.deriveReddcoinAddress(mnemonic);
      if (mounted) setState(() => _reddcoinAddress = address);
      await _syncNetworkData(address);
    }
  }

  Future<void> _syncNetworkData(String address) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    // Fetch live data in parallel
    final detailsFuture = _networkService.getAddressDetails(address);
    final priceFuture = _networkService.getLivePrice();

    final details = await detailsFuture;
    final price = await priceFuture;

    if (mounted) {
      setState(() {
        // Blockbook returns balance in base units (10^8)
        _balanceRdd = (double.tryParse(details['balance'] ?? '0') ?? 0) / 100000000;
        _fiatValueUsd = _balanceRdd * price;
        _transactions = details['transactions'] ?? [];
        _isLoading = false;
      });
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
      body: RefreshIndicator(
        color: const Color(0xFFE31B23),
        backgroundColor: const Color(0xFF1A1A1A),
        onRefresh: () => _syncNetworkData(_reddcoinAddress),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Live Balance
                  _isLoading 
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20.0),
                        child: CircularProgressIndicator(color: Color(0xFFE31B23)),
                      )
                    : Column(
                        children: [
                          Text(
                            "${_balanceRdd.toStringAsFixed(2)} RDD", 
                            style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white)
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "\$${_fiatValueUsd.toStringAsFixed(4)} USD", 
                            style: const TextStyle(fontSize: 16, color: Colors.greenAccent)
                          ),
                        ],
                      ),
                  const SizedBox(height: 20),
                  
                  // Address Display Pill
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: _reddcoinAddress));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Address copied!")));
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
                  const SizedBox(height: 30),
                  const Divider(color: Colors.white12, thickness: 1),
                ],
              ),
            ),
            
            // Dynamic Activity Feed
            SliverFillRemaining(
              child: _isLoading 
                  ? const Center(child: Text("Syncing network...", style: TextStyle(color: Colors.grey)))
                  : ActivityFeed(transactions: _transactions, currentAddress: _reddcoinAddress),
            ),
          ],
        ),
      ),
    );
  }
}
