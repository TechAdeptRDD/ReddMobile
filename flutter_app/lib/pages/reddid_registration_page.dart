import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/reddid_service.dart';
import '../services/ipfs_service.dart';
import '../services/blockbook_service.dart';
import '../services/vault_crypto_service.dart';
import '../services/secure_storage_service.dart';

class ReddIDRegistrationPage extends StatefulWidget {
  const ReddIDRegistrationPage({super.key});

  @override
  State<ReddIDRegistrationPage> createState() => _ReddIDRegistrationPageState();
}

class _ReddIDRegistrationPageState extends State<ReddIDRegistrationPage> {
  final _usernameController = TextEditingController();
  final _reddIDService = ReddIDService();
  final _ipfsService = IPFSService();
  final _blockbook = BlockbookService();
  final _vault = VaultCryptoService();
  final _storage = SecureStorageService();
  final _picker = ImagePicker();

  File? _avatarImage;
  bool _isCheckingName = false;
  bool? _isNameAvailable;
  bool _isProcessing = false;
  String _statusMessage = "";

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
    if (pickedFile != null) {
      setState(() => _avatarImage = File(pickedFile.path));
    }
  }

  void _checkName(String val) async {
    final cleanName = val.toLowerCase().replaceAll('@', '').trim();
    if (cleanName.length < 3) {
      setState(() { _isNameAvailable = null; _statusMessage = ""; });
      return;
    }
    
    setState(() { _isCheckingName = true; _statusMessage = "Scanning blockchain..."; });
    final available = await _reddIDService.isUsernameAvailable(cleanName);
    
    setState(() {
      _isCheckingName = false;
      _isNameAvailable = available;
      _statusMessage = available ? "🎉 @$cleanName is available!" : "❌ @$cleanName is taken.";
    });
  }

  Future<void> _registerIdentity() async {
    if (_avatarImage == null) {
      setState(() => _statusMessage = "Please select an avatar first.");
      return;
    }
    if (_isNameAvailable != true) {
      setState(() => _statusMessage = "Please choose an available username.");
      return;
    }

    final username = _usernameController.text.toLowerCase().replaceAll('@', '').trim();

    setState(() {
      _isProcessing = true;
      _statusMessage = "Uploading avatar to IPFS...";
    });

    try {
      final cid = await _ipfsService.uploadAvatar(_avatarImage!);
      final opReturnData = "RDD:ID:$username:$cid";

      setState(() => _statusMessage = "Preparing Blockchain Transaction...");
      final mnemonic = await _storage.getMnemonic();
      if (mnemonic == null) throw Exception("Wallet locked.");
      final myAddress = _vault.deriveReddcoinAddress(mnemonic);
      
      final utxos = await _blockbook.getUtxos(myAddress);
      if (utxos.isEmpty) throw Exception("No RDD available to pay the registration network fee.");

      utxos.sort((a, b) => int.parse(b['value'].toString()).compareTo(int.parse(a['value'].toString())));
      final int requiredSats = 100100000; 
      int gatheredSats = 0;
      List<dynamic> selectedUtxos = [];
      
      for (var utxo in utxos) {
        selectedUtxos.add(utxo);
        gatheredSats += int.parse(utxo['value'].toString());
        if (gatheredSats >= requiredSats) break;
      }
      if (gatheredSats < requiredSats) throw Exception("Insufficient funds for registration fee.");

      setState(() => _statusMessage = "Forging Cryptographic Identity...");
      final signedHex = _vault.signMultiInputTransaction(
        privateKeyHex: mnemonic,
        utxos: selectedUtxos,
        destination: myAddress, 
        amount: 1.0,            
        changeAddress: myAddress,
        opReturnData: opReturnData, 
      );

      if (signedHex.startsWith("Error")) throw Exception(signedHex);

      setState(() => _statusMessage = "Broadcasting Identity to Miners...");
      final txid = await _blockbook.broadcastTransaction(signedHex);

      setState(() {
        _statusMessage = "Success! Welcome to Web3, @$username.\nTXID: ${txid.substring(0, 16)}...";
        _isProcessing = false;
      });

    } catch (e) {
      setState(() {
        _statusMessage = "Error: ${e.toString().replaceAll('Exception: ', '')}";
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: const Text("Claim ReddID", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _isProcessing ? null : _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white10,
                    backgroundImage: _avatarImage != null ? FileImage(_avatarImage!) : null,
                    child: _avatarImage == null ? const Icon(Icons.person, size: 60, color: Colors.white54) : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFFE31B23), shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: _usernameController,
              onChanged: _checkName,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                hintText: "Enter desired username...",
                hintStyle: const TextStyle(color: Colors.white24),
                prefixText: "@ ",
                prefixStyle: const TextStyle(color: Color(0xFFE31B23), fontSize: 18, fontWeight: FontWeight.bold),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                suffixIcon: _isCheckingName 
                    ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2))
                    : (_isNameAvailable == true ? const Icon(Icons.check_circle, color: Colors.green) : null),
              ),
            ),
            const SizedBox(height: 15),
            Text(
              _statusMessage, 
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _statusMessage.contains("Error") || _isNameAvailable == false ? Colors.redAccent 
                     : _statusMessage.contains("Success") || _isNameAvailable == true ? Colors.greenAccent 
                     : Colors.grey,
                fontWeight: _isProcessing ? FontWeight.bold : FontWeight.normal,
              )
            ),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isNameAvailable == true && _avatarImage != null ? const Color(0xFFE31B23) : Colors.grey.shade800,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: (_isProcessing || _isNameAvailable != true || _avatarImage == null) ? null : _registerIdentity,
                child: _isProcessing 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("REGISTER IDENTITY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
