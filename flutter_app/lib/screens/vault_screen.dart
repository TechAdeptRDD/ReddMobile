import 'package:flutter/material.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Center(
        child: Column(
          mainAxisAlignment: Main Strategy: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Color(0xFFE31B23)),
            const SizedBox(height: 24),
            const Text("SECURE VAULT", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE31B23)),
              onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
              child: const Text("UNLOCK WALLET", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
