import 'package:flutter/material.dart';
import '../widgets/activity_feed.dart';
import '../widgets/send_dialog.dart';

class WalletTab extends StatelessWidget {
  const WalletTab({super.key});

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
            tooltip: "Send RDD",
            onPressed: () { 
              showModalBottomSheet(
                context: context, 
                isScrollControlled: true, 
                backgroundColor: Colors.transparent, 
                builder: (context) => const SendDialog()
              ); 
            }
          ),
        ],
      ),
      body: Column(
        children: [
          // Future: Add Hero Balance Card Here
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20.0),
            child: Text(
              "0.00 RDD", 
              style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white)
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20)),
            child: const Text("Network: Synchronizing...", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          const SizedBox(height: 20),
          const Expanded(child: ActivityFeed()),
        ],
      ),
    );
  }
}
