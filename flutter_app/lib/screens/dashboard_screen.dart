import 'package:flutter/material.dart';
import '../widgets/activity_feed.dart';
import '../widgets/send_dialog.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("REDDMOBILE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
        actions: [
          IconButton(
            icon: const Icon(Icons.send), 
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
      body: const ActivityFeed(),
    );
  }
}
