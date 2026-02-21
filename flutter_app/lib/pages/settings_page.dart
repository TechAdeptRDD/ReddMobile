import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../services/secure_storage_service.dart';
import '../services/vault_crypto_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SecureStorageService _storage = SecureStorageService();
  final VaultCryptoService _vault = VaultCryptoService();
  final LocalAuthentication _auth = LocalAuthentication();

  List<Map<String, String>> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final contacts = await _storage.getContacts();
    if (!mounted) return;
    setState(() {
      _contacts = contacts;
      _isLoading = false;
    });
  }

  Future<void> _removeContact(String handle) async {
    await _storage.removeContact(handle);
    _loadData();
  }

  void _generateAndShowSignature(String platform) async {
    final mnemonic = await _storage.getMnemonic();
    if (mnemonic == null) return;

    final address = _vault.deriveReddcoinAddress(mnemonic);
    final signature = _vault.generateSocialSignature("ReddID Link", platform);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF151515),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(
                  platform == "X (Twitter)"
                      ? Icons.alternate_email
                      : Icons.discord,
                  color: const Color(0xFFE31B23)),
              const SizedBox(width: 10),
              Text("Link $platform",
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  "Paste this cryptographic signature into your bio or profile description. Our decentralized indexer will verify it automatically.",
                  style:
                      TextStyle(color: Colors.grey, height: 1.4, fontSize: 14)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24)),
                child: Text(signature,
                    style: const TextStyle(
                        color: Colors.greenAccent,
                        fontFamily: 'monospace',
                        fontSize: 13,
                        letterSpacing: 1.2)),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child:
                    const Text("CLOSE", style: TextStyle(color: Colors.grey))),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE31B23),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: () {
                HapticFeedback.lightImpact();
                Clipboard.setData(ClipboardData(text: signature));
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text("Signature copied to clipboard!"),
                    backgroundColor: Color(0xFFE31B23)));
                Navigator.pop(context);
              },
              icon: const Icon(Icons.copy, color: Colors.white, size: 16),
              label: const Text("COPY",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _revealRecoveryPhrase() async {
    try {
      final bool canAuthenticate =
          await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (!canAuthenticate) {
        _showPhraseDialog("Biometrics not available to secure this action.");
        return;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason:
            'Verify identity to reveal your highly sensitive recovery phrase.',
        options: const AuthenticationOptions(stickyAuth: true),
      );

      if (didAuthenticate) {
        final mnemonic = await _storage.getMnemonic();
        if (mounted && mnemonic != null) _showPhraseDialog(mnemonic);
      }
    } catch (e) {
      _showPhraseDialog("Error accessing security enclave.");
    }
  }

  void _showPhraseDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        title: const Text("Recovery Phrase",
            style: TextStyle(
                color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text(message,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, height: 1.5)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("CLOSE", style: TextStyle(color: Colors.grey)))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
          title: const Text("Settings & Security",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFE31B23)))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Text("Web3 Social Identities",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Card(
                    color: const Color(0xFF151515),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                        leading: const Icon(Icons.alternate_email,
                            color: Colors.lightBlue),
                        title: const Text("Link X / Twitter",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        subtitle: const Text("Generate Bio Signature",
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                        trailing:
                            const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () => _generateAndShowSignature("X (Twitter)"))),
                Card(
                    color: const Color(0xFF151515),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                        leading: const Icon(Icons.discord,
                            color: Colors.deepPurpleAccent),
                        title: const Text("Link Discord",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        subtitle: const Text("Generate Bio Signature",
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                        trailing:
                            const Icon(Icons.chevron_right, color: Colors.grey),
                        onTap: () => _generateAndShowSignature("Discord"))),
                const SizedBox(height: 40),
                const Text("Localization",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Card(
                    color: const Color(0xFF151515),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    child: ListTile(
                        leading:
                            const Icon(Icons.public, color: Colors.tealAccent),
                        title: const Text("Local Currency",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        subtitle: const Text("Change fiat display",
                            style: TextStyle(color: Colors.grey, fontSize: 12)),
                        trailing: DropdownButton<String>(
                            dropdownColor: const Color(0xFF151515),
                            style: const TextStyle(color: Colors.white),
                            underline: const SizedBox(),
                            icon: const Icon(Icons.arrow_drop_down,
                                color: Colors.grey),
                            items: ["usd", "eur", "gbp", "jpy", "cad"]
                                .map((String value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value.toUpperCase())))
                                .toList(),
                            onChanged: (val) async {
                              if (val != null) {
                                await _storage.saveFiatPreference(val);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                    content: Text(
                                        "Currency updated to ${val.toUpperCase()}"),
                                    backgroundColor: const Color(0xFFE31B23)));
                              }
                            }))),
                const SizedBox(height: 40),
                const Text("Security Vault",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Card(
                  color: const Color(0xFF151515),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    leading: const Icon(Icons.vpn_key, color: Colors.amber),
                    title: const Text("Reveal Recovery Phrase",
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: const Text("Requires biometric authentication",
                        style: TextStyle(color: Colors.grey, fontSize: 12)),
                    trailing:
                        const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: _revealRecoveryPhrase,
                  ),
                ),
                const SizedBox(height: 40),
                const Text("Address Book",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (_contacts.isEmpty)
                  const Text(
                      "No saved contacts yet. Tip users to save their handles automatically.",
                      style: TextStyle(
                          color: Colors.grey, fontStyle: FontStyle.italic)),
                ..._contacts
                    .map((contact) => Card(
                          color: const Color(0xFF151515),
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.black26,
                              backgroundImage: contact["cid"] != ""
                                  ? NetworkImage(
                                      "https://gateway.pinata.cloud/ipfs/${contact["cid"]}")
                                  : null,
                              child: contact["cid"] == ""
                                  ? const Icon(Icons.person,
                                      color: Colors.white54)
                                  : null,
                            ),
                            title: Text("@${contact["handle"]}",
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.redAccent),
                              onPressed: () =>
                                  _removeContact(contact["handle"]!),
                            ),
                          ),
                        )),
              ],
            ),
    );
  }
}
