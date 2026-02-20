import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';

class SendDialog extends StatefulWidget {
  final String? initialRecipient;
  const SendDialog({super.key, this.initialRecipient});
  @override
  State<SendDialog> createState() => _SendDialogState();
}

class _SendDialogState extends State<SendDialog> {
  late ConfettiController _confettiController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
    _addressController = TextEditingController(text: widget.initialRecipient ?? "");
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Send RDD", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'To Address', labelStyle: TextStyle(color: Colors.grey))),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE31B23)),
                  onPressed: () {
                    _confettiController.play();
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted) Navigator.pop(context);
                    });
                  },
                  child: const Text("Send", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [Colors.red, Colors.white, Colors.grey],
          ),
        ],
      ),
    );
  }
}
