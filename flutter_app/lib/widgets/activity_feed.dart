import 'package:flutter/material.dart';

class ActivityFeed extends StatelessWidget {
  final List<dynamic> transactions;
  final String currentAddress;

  const ActivityFeed({super.key, required this.transactions, required this.currentAddress});

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 60, color: Colors.white.withOpacity(0.1)),
            const SizedBox(height: 16),
            const Text("No recent activity", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final tx = transactions[index];
        
        // Basic Blockbook parsing logic
        // If the 'vin' contains our address, we sent it. Otherwise, we received it.
        bool isSender = false;
        if (tx['vin'] != null) {
          for (var input in tx['vin']) {
            if (input['addresses'] != null && input['addresses'].contains(currentAddress)) {
              isSender = true;
              break;
            }
          }
        }

        final String txid = tx['txid'] ?? "Unknown";
        final String shortTxid = txid.length > 10 ? "${txid.substring(0, 5)}...${txid.substring(txid.length - 5)}" : txid;
        
        // Value is in base units (Satoshis/Reddoshis), divide by 10^8
        final double value = (double.tryParse(tx['value'] ?? '0') ?? 0) / 100000000;

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: isSender ? Colors.white.withOpacity(0.1) : const Color(0xFFE31B23).withOpacity(0.2),
            child: Icon(
              isSender ? Icons.arrow_upward : Icons.arrow_downward,
              color: isSender ? Colors.white70 : const Color(0xFFE31B23),
            ),
          ),
          title: Text(isSender ? "Sent RDD" : "Received RDD", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text("TXID: $shortTxid", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          trailing: Text(
            "${isSender ? '-' : '+'}${value.toStringAsFixed(2)}",
            style: TextStyle(
              color: isSender ? Colors.white70 : Colors.greenAccent,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        );
      },
    );
  }
}
