import 'package:flutter/material.dart';
import '../services/reddid_service.dart';
import 'reddid_registration_page.dart';

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
      setState(() { _isAvailable = null; _message = "Minimum 3 characters."; _currentSearch = ""; });
      return;
    }
    
    setState(() { _isChecking = true; _message = "Scanning blockchain..."; _currentSearch = cleanName; });
    
    final available = await _reddIDService.isUsernameAvailable(cleanName);
    
    setState(() {
      _isChecking = false;
      _isAvailable = available;
      _message = available 
          ? "🎉 @$cleanName is available!" 
          : "❌ Sorry, @$cleanName is already claimed.";
    });
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
            const SizedBox(height: 50), // Safe area for top screen
            const Text("ReddID Identity", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 10),
            const Text("Your @handle is your universal passport for tips and social credentials.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            
            TextField(
              controller: _searchController,
              onChanged: _checkName,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: "Enter username...",
                hintStyle: const TextStyle(color: Colors.white24),
                prefixText: "@ ",
                prefixStyle: const TextStyle(color: Color(0xFFE31B23), fontSize: 18, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                suffixIcon: _isChecking 
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                    : (_isAvailable == true ? const Icon(Icons.check_circle, color: Colors.green) : null),
              ),
            ),
            const SizedBox(height: 15),
            Text(_message, style: TextStyle(color: _isAvailable == false ? Colors.redAccent : Colors.grey)),
            
            const Spacer(),
            
            if (_isAvailable == true)
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE31B23),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  onPressed: () {
                    // THE NAVIGATION LINK!
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ReddIDRegistrationPage()),
                    );
                  },
                  child: Text("CLAIM @${_currentSearch.toUpperCase()}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
