import 'package:flutter/material.dart';
import '../services/blockbook_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final BlockbookService _blockbook = BlockbookService();
  Map<String, dynamic> _networkInfo = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchNetworkData();
  }

  Future<void> _fetchNetworkData() async {
    final info = await _blockbook.getNetworkInfo();
    if (mounted) {
      setState(() {
        _networkInfo = info;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final blocks = _networkInfo['blocks'] ?? 'Syncing...';
    final version = _networkInfo['version'] ?? 'Unknown';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("ReddMobile Vault", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: const Color(0xFFE31B23),
        onRefresh: _fetchNetworkData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF2A2A2A), Color(0xFF1A1A1A)]),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE31B23).withOpacity(0.5), width: 1),
              ),
              child: Column(
                children: [
                  const Text("Total Balance", style: TextStyle(color: Colors.grey, fontSize: 16)),
                  const SizedBox(height: 8),
                  const Text("0.00 RDD", style: TextStyle(color: Colors.greenAccent, fontSize: 36, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(Icons.arrow_upward, "Send", () {}),
                      _buildActionButton(Icons.arrow_downward, "Receive", () {}),
                      _buildActionButton(Icons.qr_code_scanner, "Scan", () {}),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text("Network Vitals", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE31B23)))
              : Column(
                  children: [
                    _buildStatRow("Block Height", blocks.toString(), Icons.layers),
                    const SizedBox(height: 8),
                    _buildStatRow("Core Version", version.toString(), Icons.memory),
                    const SizedBox(height: 8),
                    _buildStatRow("Connection", "Secured", Icons.security, color: Colors.greenAccent),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(backgroundColor: const Color(0xFFE31B23).withOpacity(0.2), radius: 24, child: Icon(icon, color: const Color(0xFFE31B23))),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, {Color color = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFF151515), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 20),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const Spacer(),
          Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
