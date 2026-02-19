import 'dart:math';
import 'package:flutter/material.dart';
import '../services/secure_storage_service.dart';
import '../main.dart';

class VerifyPhrasePage extends StatefulWidget {
  final String mnemonic;
  const VerifyPhrasePage({super.key, required this.mnemonic});

  @override
  State<VerifyPhrasePage> createState() => _VerifyPhrasePageState();
}

class _VerifyPhrasePageState extends State<VerifyPhrasePage> {
  late List<String> _words;
  late List<int> _missingIndices;
  late List<String> _shuffledBank;
  Map<int, String?> _selectedAnswers = {};

  @override
  void initState() {
    super.initState();
    _words = widget.mnemonic.split(' ');
    _generateChallenge();
  }

  void _generateChallenge() {
    final random = Random();
    Set<int> indices = {};
    while (indices.length < 3) { indices.add(random.nextInt(12)); }
    _missingIndices = indices.toList()..sort();
    
    List<String> bank = [];
    for (int i in _missingIndices) { bank.add(_words[i]); }
    
    // Add some fake words for the multiple choice
    final fakes = ["apple", "river", "crypto", "rocket", "pizza", "galaxy"];
    fakes.shuffle();
    bank.addAll(fakes.take(3));
    bank.shuffle();
    _shuffledBank = bank;
  }

  void _verifyAndProceed() async {
    for (int i in _missingIndices) {
      if (_selectedAnswers[i] != _words[i]) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Incorrect words. Try again."), backgroundColor: Colors.redAccent));
        return;
      }
    }
    
    // They passed! Save to secure enclave and enter app.
    final storage = SecureStorageService();
    await storage.saveMnemonic(widget.mnemonic);
    if (mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainNavigation()), (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(title: const Text("Verify Phrase", style: TextStyle(color: Colors.white)), backgroundColor: Colors.transparent, elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text("Tap the missing words to verify your backup.", style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 20),
            
            // The fill-in-the-blank grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 3.5, crossAxisSpacing: 10, mainAxisSpacing: 10),
                itemCount: 12,
                itemBuilder: (context, index) {
                  if (_missingIndices.contains(index)) {
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAnswers.remove(index)), // Deselect
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: _selectedAnswers[index] == null ? Colors.transparent : const Color(0xFFE31B23).withOpacity(0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE31B23), style: _selectedAnswers[index] == null ? BorderStyle.solid : BorderStyle.none)),
                        child: Text(_selectedAnswers[index] ?? "Tap word below", style: TextStyle(color: _selectedAnswers[index] == null ? Colors.grey : Colors.white, fontSize: 14)),
                      ),
                    );
                  }
                  return Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(color: const Color(0xFF151515), borderRadius: BorderRadius.circular(10)),
                    child: Text("${index + 1}. ${_words[index]}", style: const TextStyle(color: Colors.white54, fontSize: 16)),
                  );
                },
              ),
            ),
            
            // The Word Bank
            const Text("Word Bank", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _shuffledBank.map((word) {
                final isUsed = _selectedAnswers.containsValue(word);
                return ActionChip(
                  backgroundColor: isUsed ? Colors.black : const Color(0xFF151515),
                  label: Text(word, style: TextStyle(color: isUsed ? Colors.white24 : Colors.white)),
                  onPressed: isUsed ? null : () {
                    for (int i in _missingIndices) {
                      if (_selectedAnswers[i] == null) {
                        setState(() => _selectedAnswers[i] = word);
                        break;
                      }
                    }
                  },
                );
              }).toList(),
            ),
            
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE31B23), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: _selectedAnswers.length == 3 ? _verifyAndProceed : null,
                child: const Text("VERIFY & ENTER WALLET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
