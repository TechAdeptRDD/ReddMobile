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
        title: Image.asset('assets/branding/redd_logo_dark.png', height: 24),
        actions: [
          IconButton(
            icon: const Icon(Icons.send, color: Color(0xFFE31B23)), 
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
          // ReddID Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search ReddID (e.g. techadept)",
                prefixIcon: const Icon(Icons.search, color: Color(0xFFE31B23)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              onSubmitted: (value) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Searching for handle: $value...")));
              },
            ),
          ),
          const Expanded(child: ActivityFeed()),
        ],
      ),
    );
  }
}
