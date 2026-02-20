import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../services/reddid_service.dart';
import 'reddid_registration_page.dart';
import '../widgets/send_dialog.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {
  final TextEditingController _searchController = TextEditingController();
  final ReddIDService _reddIDService = ReddIDService();

  bool _isChecking = false;
  bool? _isAvailable;
  String _message = "Search for a unique @handle to link to your wallet.";
  String _currentSearch = "";

  void _checkName(String val) async {
    final cleanName = val.toLowerCase().replaceAll('@', '').trim();
    if (cleanName.length < 3) {
      setState(() {
        _isAvailable = null;
        _message = "Minimum 3 characters.";
        _currentSearch = "";
      });
      return;
    }

    setState(() {
      _isChecking = true;
      _message = "Scanning blockchain...";
      _currentSearch = cleanName;
    });

    final available = await _reddIDService.isUsernameAvailable(cleanName);

    setState(() {
      _isChecking = false;
      _isAvailable = available;
      _message =
          available ? "🎉 @$cleanName is available!" : "🔍 Identity Found!";
    });
  }

  void _openTipDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SendDialog(initialRecipient: "@$_currentSearch"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 50),
            const Text("ReddID Network",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 10),
            const Text(
                "Search for an identity to tip them, or claim an available handle for yourself.",
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),

            TextField(
              controller: _searchController,
              onChanged: _checkName,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: "Enter username...",
                hintStyle: const TextStyle(color: Colors.white24),
                prefixText: "@ ",
                prefixStyle: const TextStyle(
                    color: Color(0xFFE31B23),
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide.none),
                suffixIcon: _isChecking
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : (_isAvailable == true
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : null),
              ),
            ),
            const SizedBox(height: 15),
            Text(_message,
                style: TextStyle(
                    color: _isAvailable == false
                        ? Colors.greenAccent
                        : Colors.grey)),

            const Spacer(),

            // Layout changes based on if the name is claimed or available
            if (_isAvailable == true)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31B23),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15))),
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const ReddIDRegistrationPage())),
                  child: Text("CLAIM @${_currentSearch.toUpperCase()}",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),

            if (_isAvailable == false) ...[
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE31B23),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15))),
                  onPressed: _openTipDialog,
                  icon:
                      const Icon(Icons.volunteer_activism, color: Colors.white),
                  label: Text("TIP @${_currentSearch.toUpperCase()}",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey, width: 1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15))),
                  onPressed: () => Share.share(
                      "Send me crypto on ReddMobile!\n\nTap here to tip: redd://pay?user=@$_currentSearch"),
                  icon: const Icon(Icons.share, color: Colors.white),
                  label: const Text("SHARE PROFILE LINK",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
