import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ipfs_service.dart';
import '../services/vault_crypto_service.dart';
import '../services/blockbook_service.dart';
import '../services/secure_storage_service.dart';

class ReddIDRegistrationPage extends StatefulWidget {
  final String? prefilledHandle;
  const ReddIDRegistrationPage({super.key, this.prefilledHandle});

  @override
  State<ReddIDRegistrationPage> createState() => _ReddIDRegistrationPageState();
}

class _ReddIDRegistrationPageState extends State<ReddIDRegistrationPage> {
  final _handleController = TextEditingController();
  final _picker = ImagePicker();
  final _ipfs = IpfsService();
  final _vault = VaultCryptoService();
  final _blockbook = BlockbookService();
  final _storage = SecureStorageService();

  File? _selectedImage;
  bool _isProcessing = false;
  String _status = "";

  @override
  void initState() {
    super.initState();
    if (widget.prefilledHandle != null) {
      _handleController.text = widget.prefilledHandle!;
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70, maxWidth: 400);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }


  List<Map<String, dynamic>> _selectUtxosForFee(
    List<dynamic> rawUtxos,
    int estimatedFeeSats,
  ) {
    final normalized = rawUtxos
        .whereType<Map<String, dynamic>>()
        .map((utxo) => Map<String, dynamic>.from(utxo))
        .toList();

    normalized.sort((a, b) {
      final aValue = int.tryParse('${a['value'] ?? a['amount'] ?? 0}') ?? 0;
      final bValue = int.tryParse('${b['value'] ?? b['amount'] ?? 0}') ?? 0;
      return bValue.compareTo(aValue);
    });

    final selected = <Map<String, dynamic>>[];
    var total = 0;

    for (final utxo in normalized) {
      final value = int.tryParse('${utxo['value'] ?? utxo['amount'] ?? 0}') ?? 0;
      if (value <= 0) continue;

      selected.add(utxo);
      total += value;

      final dynamicFee = estimatedFeeSats + ((selected.length - 1) * 148);
      if (total >= dynamicFee) {
        return selected;
      }
    }

    throw Exception('Insufficient confirmed funds for network fee.');
  }

  Future<void> _registerIdentity() async {
    final handle =
        _handleController.text.trim().toLowerCase().replaceAll('@', '');
    if (handle.length < 3) {
      setState(() => _status = "Handle must be at least 3 characters.");
      return;
    }

    setState(() {
      _isProcessing = true;
      _status = "Initializing Registration...";
    });

    try {
      String cid = "";

      // 1. Upload to IPFS natively if an image is selected
      if (_selectedImage != null) {
        setState(() => _status = "Pinning Avatar to IPFS Network...");
        final uploadedCid = await _ipfs.uploadAvatar(_selectedImage!);
        if (uploadedCid == null)
          throw Exception("Failed to secure image on decentralized web.");
        cid = uploadedCid;
      }

      // 2. Prepare the blockchain transaction
      setState(() => _status = "Securing Identity on Blockchain...");
      final mnemonic = await _storage.getMnemonic();
      if (mnemonic == null) throw Exception("Wallet locked.");

      final myAddress = _vault.deriveReddcoinAddress(mnemonic);
      final utxos = await _blockbook.getUtxos(myAddress);
      if (utxos.isEmpty)
        throw Exception("No RDD available to pay network registration fee.");

      final int estimatedFeeSats = await _blockbook.estimateFee();
      final selectedUtxos = _selectUtxosForFee(utxos, estimatedFeeSats);

      // We send 0 RDD to ourselves, just paying the network fee to embed the OP_RETURN.
      final signedHex = _vault.signMultiInputTransaction(
        privateKeyHex: mnemonic,
        utxos: selectedUtxos,
        destination: myAddress,
        amount: 0.0,
        changeAddress: myAddress,
        opReturnData: "RDD:ID:$handle:$cid",
      );

      if (signedHex.startsWith("Error")) throw Exception(signedHex);

      setState(() => _status = "Broadcasting to Miners...");
      final txid = await _blockbook.broadcastTransaction(signedHex);

      setState(() {
        _status =
            "Success! Welcome to the network, @$handle.\\nTXID: ${txid.substring(0, 10)}...";
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _status = "Error: ${e.toString().replaceAll('Exception: ', '')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
          title: const Text("Claim ReddID",
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.transparent,
          elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text("Your Web3 Identity",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
                "Upload an avatar and choose a handle. This will be permanently secured on the ReddCoin blockchain.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 40),

            // Native Image Picker Avatar
            GestureDetector(
              onTap: _isProcessing ? null : _pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFF151515),
                backgroundImage:
                    _selectedImage != null ? FileImage(_selectedImage!) : null,
                child: _selectedImage == null
                    ? const Icon(Icons.add_a_photo,
                        color: Color(0xFFE31B23), size: 40)
                    : null,
              ),
            ),
            const SizedBox(height: 15),
            const Text("Tap to select avatar",
                style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 40),

            TextField(
              controller: _handleController,
              enabled: !_isProcessing,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                labelText: "Choose your @handle",
                labelStyle: const TextStyle(color: Colors.grey),
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
              ),
            ),
            const SizedBox(height: 30),

            if (_status.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(_status,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: _status.contains("Error")
                            ? Colors.redAccent
                            : Colors.greenAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE31B23),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15))),
                onPressed: _isProcessing ? null : _registerIdentity,
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("REGISTER IDENTITY",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
