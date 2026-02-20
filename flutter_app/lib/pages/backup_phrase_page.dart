import 'package:flutter/material.dart';
import 'verify_phrase_page.dart';

class BackupPhrasePage extends StatelessWidget {
  final String mnemonic;
  const BackupPhrasePage({super.key, required this.mnemonic});

  @override
  Widget build(BuildContext context) {
    final words = mnemonic.split(' ');

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("Secure Your Wallet",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.security, size: 60, color: Color(0xFFE31B23)),
            const SizedBox(height: 20),
            const Text("Write Down Your Secret Phrase",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 10),
            const Text(
                "This is the ONLY way to recover your account if you lose your phone. Do not take a screenshot.",
                style: TextStyle(color: Colors.redAccent, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3.5,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10),
                itemCount: words.length,
                itemBuilder: (context, index) {
                  return Container(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                        color: const Color(0xFF151515),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white10)),
                    child: Text("${index + 1}. ${words[index]}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  );
                },
              ),
            ),
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
                        builder: (_) => VerifyPhrasePage(mnemonic: mnemonic))),
                child: const Text("I WROTE IT DOWN",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
