import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
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
  late ConfettiController _confettiController;
  
  final _blockbook = BlockbookService();
  final _vault = VaultCryptoService();
  final _storage = SecureStorageService();
  final _resolver = ProfileResolverService();

  bool _isProcessing = false;
  bool _isResolving = false;
  bool _isSuccess = false;
  String _statusMessage = "";
  String _txid = "";
  String? _resolvedAddress;
  String? _resolvedCid;
  List<Map<String, String>> _contacts = [];

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _loadContacts();
    _addressController = TextEditingController(text: widget.initialRecipient ?? "");
    _addressController.addListener(_onAddressChanged);
    
    if (widget.initialRecipient != null && widget.initialRecipient!.isNotEmpty) {
      _onAddressChanged();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
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

  void _setSmartTip(String amount, String memo) {
    HapticFeedback.lightImpact();
    setState(() {
      _amountController.text = amount;
      _memoController.text = memo;
    });
  }

  Future<void> _processTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    final finalDestination = _resolvedAddress ?? _addressController.text.trim();
    if (finalDestination.isEmpty) return;

    setState(() { _isProcessing = true; _statusMessage = "Forging Transaction..."; });

    try {
      final double amountRdd = double.parse(_amountController.text.trim());
      final int amountSats = (amountRdd * 100000000).toInt(); 
      final int estimatedFeeSats = await _blockbook.estimateFee();

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

      if (_addressController.text.startsWith('@')) {
         await _storage.addContact(_addressController.text, cid: _resolvedCid ?? "");
      }

      setState(() {
        _isSuccess = true;
        _isProcessing = false;
        _statusMessage = "Tip Sent Successfully!";
      });
      
      // Trigger the Redd Rain!
      _confettiController.play();

        _txid = txid;

    } catch (e) {
      setState(() { _statusMessage = "Error: ${e.toString().replaceAll('Exception: ', '')}"; _isProcessing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Container(
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

                const Text("Community Causes:", style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ActionChip(backgroundColor: Colors.black26, side: const BorderSide(color: Colors.greenAccent, width: 1), avatar: const Icon(Icons.favorite, size: 14, color: Colors.greenAccent), label: const Text("Dev Fund", style: TextStyle(color: Colors.white)), onPressed: () { _addressController.text = "RvY...DevFundAddress"; _onAddressChanged(); }),
                      const SizedBox(width: 8),
                      ActionChip(backgroundColor: Colors.black26, side: const BorderSide(color: Colors.blueAccent, width: 1), avatar: const Icon(Icons.water_drop, size: 14, color: Colors.blueAccent), label: const Text("Clean Water", style: TextStyle(color: Colors.white)), onPressed: () { _addressController.text = "RcW...CharityAddress"; _onAddressChanged(); }),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

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
                            avatar: _contacts[index]["cid"] != "" 
                                ? CircleAvatar(backgroundImage: NetworkImage("https://gateway.pinata.cloud/ipfs/${_contacts[index]["cid"]}"))
                                : const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.person, size: 12, color: Colors.white)),
                            child: Text("@${_contacts[index]["handle"]}", style: const TextStyle(color: Colors.white)),
                            onPressed: () {
                              _addressController.text = "@${_contacts[index]["handle"]}";
                              _onAddressChanged();
                            },
                          ),
                            child: Text("@${_contacts[index]}", style: const TextStyle(color: Colors.white)),
                            onPressed: () {
                              _addressController.text = "@${_contacts[index]}";
                              _onAddressChanged();
                            },
                          ),
                        ),
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
                
                // Smart Tip Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSmartTipButton("50", "☕ Coffee"),
                    _buildSmartTipButton("100", "🍺 Beer"),
                    _buildSmartTipButton("500", "🍕 Pizza"),
                  ],
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
                
                if (_statusMessage.isNotEmpty) 
                  Center(child: Padding(padding: const EdgeInsets.only(bottom: 15.0), child: Text(_statusMessage, style: TextStyle(color: _statusMessage.contains("Error") ? Colors.redAccent : Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold)))),
                
                if (_isSuccess) ...[
                  const Center(child: Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 60)),
                  const SizedBox(height: 15),
                  const Center(child: Text("Transaction Confirmed", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity, height: 55,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE31B23), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                      onPressed: () => Share.share("I just tipped ${_addressController.text} on the ReddMobile Network! 🚀\n\nVerify my transaction: https://live.reddcoin.com/tx/$_txid"),
                      icon: const Icon(Icons.share, color: Colors.white),
                      label: const Text("SHARE RECEIPT", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Center(child: Text("CLOSE", style: TextStyle(color: Colors.grey)))),
                ],

                if (!_isSuccess)
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
        ),
        
        // The Confetti Cannon!
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          emissionFrequency: 0.05,
          numberOfParticles: 20,
          gravity: 0.3,
          colors: const [Colors.red, Color(0xFFE31B23), Colors.white],
        ),
      ],
    );
  }

  Widget _buildSmartTipButton(String amount, String label) {
    return ActionChip(
      backgroundColor: Colors.black26,
      side: const BorderSide(color: Colors.grey, width: 1),
      child: Text(label, style: const TextStyle(color: Colors.white)),
      onPressed: () => _setSmartTip(amount, label),
    );
  }
}
