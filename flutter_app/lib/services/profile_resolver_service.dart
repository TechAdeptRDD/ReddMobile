import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileResolverService {
  final String _baseUrl = "https://blockbook.reddcoin.com/api/v2";
  
  // The global index address we defined earlier to track all registrations
  final String _indexAddress = "Ru6sB6S79Z86V99Xy3S6sB6S79Z86V99Xy3"; 

  /// Scans the blockchain and resolves a @handle into a real address and avatar CID
  Future<Map<String, String>?> resolveUsername(String username) async {
    try {
      final cleanName = username.toLowerCase().replaceAll('@', '').trim();
      final response = await http.get(Uri.parse('$_baseUrl/address/$_indexAddress'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List txs = data['transactions'] ?? [];

        // Search the ledger history for this specific identity claim
        for (var tx in txs) {
          for (var vout in tx['vout']) {
            final String asm = vout['scriptPubKey']['asm'] ?? "";
            
            // Check if this transaction contains our OP_RETURN protocol
            if (asm.contains("OP_RETURN") && asm.contains(hexEncode("RDD:ID:$cleanName:"))) {
               
               // In a production indexer, this is parsed via dedicated APIs.
               // Here we extract the payload dynamically from the raw ASM hex.
               final hexPayload = asm.split("OP_RETURN ")[1];
               final decoded = hexDecode(hexPayload);
               final parts = decoded.split(":");
               
               if (parts.length >= 4) {
                 // Protocol Format: RDD:ID:username:cid
                 return {
                   "address": tx['vin'][0]['addresses'][0], // The verified address that paid for the registration
                   "cid": parts[3]                          // The IPFS hash for their avatar
                 };
               }
            }
          }
        }
      }
    } catch (e) {
      print("Resolver Error: $e");
    }
    return null; // Identity not found on-chain
  }

  String hexEncode(String input) {
    return utf8.encode(input).map((e) => e.toRadixString(16).padLeft(2, '0')).join();
  }

  String hexDecode(String hex) {
    String result = "";
    for (int i = 0; i < hex.length; i += 2) {
      try {
        String part = hex.substring(i, i + 2);
        result += String.fromCharCode(int.parse(part, radix: 16));
      } catch (e) {
        continue; // Skip invalid hex blocks
      }
    }
    return result;
  }
}
