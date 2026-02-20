import 'package:flutter/material.dart';

class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    const String appVersion =
        String.fromEnvironment('APP_VERSION', defaultValue: 'v0.3.0-Beta');

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Settings",
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.security, color: Color(0xFFE31B23)),
            title: const Text("Backup Wallet",
                style: TextStyle(color: Colors.white)),
            subtitle: const Text("View your 12-word recovery phrase",
                style: TextStyle(color: Colors.grey)),
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            onTap: () {
              // Future: Call VaultCryptoService to reveal mnemonic
            },
          ),
          ListTile(
            leading: const Icon(Icons.fingerprint, color: Color(0xFFE31B23)),
            title: const Text("Require Biometrics",
                style: TextStyle(color: Colors.white)),
            trailing: Switch(
                value: true,
                onChanged: (val) {},
                activeColor: const Color(0xFFE31B23)),
          ),
          const Divider(color: Colors.white24),
          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.grey),
            title: const Text("About ReddMobile",
                style: TextStyle(color: Colors.white)),
            subtitle: Text("Version $appVersion",
                style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}
