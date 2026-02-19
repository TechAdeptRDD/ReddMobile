import 'package:flutter/material.dart';
import '../services/blockbook_service.dart';
import '../services/vault_crypto_service.dart';
import '../services/secure_storage_service.dart';
import '../services/profile_resolver_service.dart';

class SendDialog extends StatefulWidget {
  final String? initialRecipient;
  const SendDialog({super.key, this.initialRecipient});

  @override
  State<SendDialog> createState() => _SendDialogState();
}

class _SendDialogState extends State<SendDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _addressController;
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  
  final _blockbook = BlockbookService();
  final _vault = VaultCryptoService();
  final _storage = SecureStorageService();
  final _resolver = ProfileResolverService();

  bool _isProcessing = false;
  bool _isResolving = false;
  String _statusMessage = "";
  String? _resolvedAddress;
  String? _resolvedCid;
  List<String> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _addressController = TextEditingController(text: widget.initialRecipient ?? "");
    _addressController.addListener(_onAddressChanged);
    
    if (widget.initialRecipient != null && widget.initialRecipient!.isNotEmpty) {
      _onAddressChanged();
    }
  }

  Future<void> _loadContacts() async {
    final contacts = await _storage.getContacts();
    setState(() => _contacts = contacts);
  }

  void _onAddressChanged() async {
    final text = _addressController.text.trim();
    if (text.startsWith('@') && text.length > 3) {
      setState(() { _isResolving = true; _resolvedAddress = null; _resolvedCid = null; });
      final profile = await _resolver.resolveUsername(text);
      if (mounted) {
        setState(() {
          _isResolving = false;
          if (profile != null) {
            _resolvedAddress = profile["address"];
            _resolvedCid = profile["cid"];
          }
        });
      }
    } else {
      setState(() { _resolvedAddress = null; _resolvedCid = null; _isResolving = false; });
    }
  }

  Future<void> _processTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    final finalDestination = _resolvedAddress ?? _addressController.text.trim();
    if (finalDestination.isEmpty) return;

    setState(() { _isProcessing = true; _statusMessage = "Securing network data..."; });

    try {
      final double amountRdd = double.parse(_amountController.text.trim());
      final int amountSats = (amountRdd * 100000000).toInt(); 
      final int estimatedFeeSats = 100000;

      final mnemonic = await _storage.getMnemonic();
      if (mnemonic == null) throw Exception("Wallet locked.");
      final myAddress = _vault.deriveReddcoinAddress(mnemonic);

      final utxos = await _blockbook.getUtxos(myAddress);
      if (utxos.isEmpty) throw Exception("No unspent coins available.");

      utxos.sort((a, b) => int.parse(b['value'].toString()).compareTo(int.parse(a['value'].toString())));
      
      List<dynamic> selectedUtxos = [];
      int gatheredSats = 0;
      for (var utxo in utxos) {
        selectedUtxos.add(utxo);
        gatheredSats += int.parse(utxo['value'].toString());
        if (gatheredSats >= (amountSats + estimatedFeeSats)) break;
      }

      if (gatheredSats < (amountSats + estimatedFeeSats)) throw Exception("Insufficient funds.");

      setState(() => _statusMessage = "Forging signatures offline...");
      final signedHex = _vault.signMultiInputTransaction(
        privateKeyHex: mnemonic, 
        utxos: selectedUtxos,
        destination: finalDestination,
        amount: amountRdd,
        changeAddress: myAddress,
        opReturnData: _memoController.text.isNotEmpty ? "RDD:MSG:${_memoController.text}" : null,
      );

      if (signedHex.startsWith("Error")) throw Exception(signedHex);

      setState(() => _statusMessage = "Broadcasting to miners...");
      final txid = await _blockbook.broadcastTransaction(signedHex);

      // UX Upgrade: Auto-save handle to contacts upon successful tip!
      if (_addressController.text.startsWith('@')) {
         await _storage.addContact(_addressController.text);
      }

      setState(() {
        _statusMessage = "Success! TXID:\n${txid.substring(0, 16)}...";
        _isProcessing = false;
      });

      await Future.delayed(const Duration(seconds: 4));
      if (mounted) Navigator.pop(context);

    } catch (e) {
      setState(() { _statusMessage = "Error: ${e.toString().replaceAll('Exception: ', '')}"; _isProcessing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
      decoration: const BoxDecoration(color: Color(0xFF151515), borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Send RDD", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 15),

            // UX Upgrade: Quick-Select Contacts Row
            if (_contacts.isNotEmpty) ...[
              const Text("Quick Select:", style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _contacts.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        backgroundColor: Colors.black26,
                        side: const BorderSide(color: Color(0xFFE31B23), width: 1),
                        label: Text("@${_contacts[index]}", style: const TextStyle(color: Colors.white)),
                        onPressed: () {
                          _addressController.text = "@${_contacts[index]}";
                          _onAddressChanged();
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 15),
            ],
            
            if (_isResolving) const Padding(padding: EdgeInsets.only(bottom: 10), child: Text("Resolving ReddID...", style: TextStyle(color: Colors.amber))),
            if (_resolvedAddress != null)
               Padding(
                 padding: const EdgeInsets.only(bottom: 15),
                 child: Row(
                   children: [
                     CircleAvatar(
                       radius: 20,
                       backgroundColor: Colors.white10,
                       backgroundImage: _resolvedCid != null && _resolvedCid!.isNotEmpty ? NetworkImage("https://gateway.pinata.cloud/ipfs/$_resolvedCid") : null,
                       child: _resolvedCid == null ? const Icon(Icons.check_circle, color: Colors.green) : null,
                     ),
                     const SizedBox(width: 10),
                     Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                           const Text("Verified Identity Found", style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                           Text(_resolvedAddress!.substring(0, 16) + "...", style: const TextStyle(color: Colors.grey, fontSize: 11)),
                     ]))
                   ],
                 ),
               ),
            TextFormField(
              controller: _addressController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(labelText: "Recipient Address or @username", labelStyle: const TextStyle(color: Colors.grey), prefixIcon: const Icon(Icons.send_to_mobile, color: Color(0xFFE31B23)), filled: true, fillColor: Colors.black26, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
              validator: (val) {
                 if (val == null || val.isEmpty) return "Required";
                 if (val.startsWith('@') && _resolvedAddress == null && !_isResolving) return "Identity not found on blockchain.";
                 return null;
              },
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(labelText: "Amount (RDD)", labelStyle: const TextStyle(color: Colors.grey), prefixIcon: const Icon(Icons.monetization_on, color: Color(0xFFE31B23)), filled: true, fillColor: Colors.black26, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
              validator: (val) {
                if (val == null || val.isEmpty) return "Required";
                if (double.tryParse(val) == null) return "Invalid number";
                return null;
              },
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _memoController,
              style: const TextStyle(color: Colors.white),
              maxLength: 40,
              decoration: InputDecoration(labelText: "Public Memo (Optional)", labelStyle: const TextStyle(color: Colors.grey), prefixIcon: const Icon(Icons.chat_bubble_outline, color: Color(0xFFE31B23)), filled: true, fillColor: Colors.black26, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 15),
            if (_statusMessage.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 15.0), child: Text(_statusMessage, style: TextStyle(color: _statusMessage.contains("Error") ? Colors.redAccent : Colors.greenAccent, fontSize: 14))),
            SizedBox(
              width: double.infinity, height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE31B23), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: _isProcessing ? null : _processTransaction,
                child: _isProcessing ? const CircularProgressIndicator(color: Colors.white) : const Text("SEND REDDCOIN", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
