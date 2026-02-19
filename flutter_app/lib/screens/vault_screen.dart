import 'package:flutter/material.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We grab the version from the build-time variable we set in GitHub Actions
    const String appVersion = String.fromEnvironment('APP_VERSION', defaultValue: 'v0.0.0-dev');

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Build: $appVersion",
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
