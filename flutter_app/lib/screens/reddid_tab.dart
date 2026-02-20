import 'package:flutter/material.dart';

class ReddIDTab extends StatelessWidget {
  const ReddIDTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("ReddID Social",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Search & Claim Identities",
                style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                hintText: "Search handle (e.g. techadept)",
                prefixIcon:
                    const Icon(Icons.alternate_email, color: Color(0xFFE31B23)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Icon(Icons.hub,
                      size: 80, color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 20),
                  const Text("ReddID registration coming in Phase 2",
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
