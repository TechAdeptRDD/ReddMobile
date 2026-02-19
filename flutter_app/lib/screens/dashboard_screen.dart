import 'package:flutter/material.dart';
import '../widgets/activity_feed.dart';
import '../widgets/send_dialog.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const String appVersion = String.fromEnvironment('APP_VERSION', defaultValue: 'dev');

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("REDDMOBILE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 18)),
            Text(appVersion, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
          ],
        ),
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
