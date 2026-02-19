import 'package:flutter/material.dart';
import '../services/blockbook_service.dart';
import '../services/vault_crypto_service.dart';
import '../services/secure_storage_service.dart';

class SendDialog extends StatefulWidget {
  const SendDialog({super.key});

  @override
  State<SendDialog> createState() => _SendDialogState();
}

class _SendDialogState extends State<SendDialog> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _amountController = TextEditingController();
  
  bool _isProcessing = false;
  String _statusMessage = "";

  final BlockbookService _blockbook = BlockbookService();
  final VaultCryptoService _vault = VaultCryptoService();
  final SecureStorageService _storage = SecureStorageService();

  Future<void> _processTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = "Fetching network data...";
    });

    try {
      final destination = _addressController.text.trim();
      final double amountRdd = double.parse(_amountController.text.trim());
      final int amountSats = (amountRdd * 100000000).toInt(); // Convert to base units
      final int estimatedFeeSats = 100000; // 0.001 RDD standard fee buffer

      // 1. Get our local address & mnemonic
      final mnemonic = await _storage.getMnemonic();
      if (mnemonic == null) throw Exception("Wallet locked or missing.");
      final myAddress = _vault.deriveReddcoinAddress(mnemonic);

      // 2. Fetch UTXOs
      setState(() => _statusMessage = "Gathering UTXOs...");
      final utxos = await _blockbook.getUTXOs(myAddress);
      
      if (utxos.isEmpty) throw Exception("No unspent coins available.");

      // 3. UTXO Coin Selection Algorithm (Simple Largest-First for Alpha)
      // Sort largest to smallest to minimize input count
      utxos.sort((a, b) => int.parse(b['value']).compareTo(int.parse(a['value'])));
      
      List<dynamic> selectedUtxos = [];
      int gatheredSats = 0;
      
      for (var utxo in utxos) {
        selectedUtxos.add(utxo);
        gatheredSats += int.parse(utxo['value']);
        if (gatheredSats >= (amountSats + estimatedFeeSats)) break;
      }

      if (gatheredSats < (amountSats + estimatedFeeSats)) {
        throw Exception("Insufficient funds. You need ${(amountSats + estimatedFeeSats) / 100000000} RDD.");
      }

      // 4. Send to Rust Core for Construction & Signing
      setState(() => _statusMessage = "Signing transaction securely...");
      
      // Note: Rust currently returns a mock string until we build the serializer.
      final signedHex = _vault.signMultiInputTransaction(
        privateKeyHex: "derivation_pending_in_rust", 
        utxos: selectedUtxos,
        destination: destination,
        amount: amountRdd,
        changeAddress: myAddress,
      );

      // 5. Success UI
      setState(() {
        _statusMessage = "Success! Hex generated:\n${signedHex.substring(0, 15)}...";
        _isProcessing = false;
      });

      await Future.delayed(const Duration(seconds: 3));
      if (mounted) Navigator.pop(context);

    } catch (e) {
      setState(() {
        _statusMessage = "Error: ${e.toString()}";
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20, right: 20, top: 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF151515),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Send RDD", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            
            TextFormField(
              controller: _addressController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Recipient Address or ReddID",
                labelStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.send_to_mobile, color: Color(0xFFE31B23)),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              validator: (val) => val == null || val.isEmpty ? "Required" : null,
            ),
            const SizedBox(height: 15),
            
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Amount (RDD)",
                labelStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.monetization_on, color: Color(0xFFE31B23)),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
              validator: (val) {
                if (val == null || val.isEmpty) return "Required";
                if (double.tryParse(val) == null) return "Invalid number";
                return null;
              },
            ),
            const SizedBox(height: 25),

            if (_statusMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: Text(_statusMessage, style: TextStyle(color: _statusMessage.contains("Error") ? Colors.redAccent : Colors.greenAccent)),
              ),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE31B23),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _isProcessing ? null : _processTransaction,
                child: _isProcessing 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("PREPARE TRANSACTION", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
