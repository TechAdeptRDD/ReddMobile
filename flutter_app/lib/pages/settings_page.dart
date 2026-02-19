import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/secure_storage_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SecureStorageService _storage = SecureStorageService();
  final LocalAuthentication _auth = LocalAuthentication();
  
  List<String> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final contacts = await _storage.getContacts();
    setState(() {
      _contacts = contacts;
      _isLoading = false;
    });
  }

  Future<void> _removeContact(String handle) async {
    _contacts.remove(handle);
    await _storage.saveContacts(_contacts);
    setState(() {});
  }

  Future<void> _revealRecoveryPhrase() async {
    try {
      final bool canAuthenticate = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (!canAuthenticate) {
        _showPhraseDialog("Biometrics not available to secure this action.");
        return;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: 'Verify identity to reveal your highly sensitive recovery phrase.',
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

  void _showSocialLinkDialog(String platform) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        title: Text("Link $platform", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("In V2, this will encrypt your social handle into your ReddID IPFS payload, allowing seamless cross-platform tipping across the web.", style: TextStyle(color: Colors.grey, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("GOT IT", style: TextStyle(color: Color(0xFFE31B23)))),
        ],
      ),
    );
  }

  void _showPhraseDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF151515),
        title: const Text("Recovery Phrase", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: Colors.white, fontSize: 18, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE", style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(title: const Text("Settings & Security", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), backgroundColor: Colors.transparent, elevation: 0),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFFE31B23)))
        : ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text("Security Vault", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Card(
                color: const Color(0xFF151515),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: const Icon(Icons.vpn_key, color: Colors.amber),
                  title: const Text("Reveal Recovery Phrase", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text("Requires biometric authentication", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: _revealRecoveryPhrase,
                ),
              ),
              const SizedBox(height: 40),
              
              const Text("Web3 Social Identities", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Card(color: const Color(0xFF151515), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: ListTile(leading: const Icon(Icons.alternate_email, color: Colors.lightBlue), title: const Text("Link X / Twitter", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), trailing: const Icon(Icons.add_link, color: Colors.grey), onTap: () => _showSocialLinkDialog("X (Twitter)"))),
              Card(color: const Color(0xFF151515), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: ListTile(leading: const Icon(Icons.telegram, color: Colors.blueAccent), title: const Text("Link Telegram", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), trailing: const Icon(Icons.add_link, color: Colors.grey), onTap: () => _showSocialLinkDialog("Telegram"))),
              Card(color: const Color(0xFF151515), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), child: ListTile(leading: const Icon(Icons.discord, color: Colors.deepPurpleAccent), title: const Text("Link Discord", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), trailing: const Icon(Icons.add_link, color: Colors.grey), onTap: () => _showSocialLinkDialog("Discord"))),
              const SizedBox(height: 40),

              const Text("Address Book", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              if (_contacts.isEmpty)
                const Text("No saved contacts yet. Tip users to save their handles automatically.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              
              ..._contacts.map((contact) => Card(
                color: const Color(0xFF151515),
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.black26, child: Icon(Icons.person, color: Colors.white54)),
                  title: Text("@$contact", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () => _removeContact(contact),
                  ),
                ),
              )).toList(),
            ],
          ),
    );
  }
}
