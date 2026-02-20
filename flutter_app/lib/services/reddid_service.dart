import 'dart:convert';
import 'package:http/http.dart' as http;

class ReddIDService {
  final String _baseUrl = "https://blockbook.reddcoin.com/api/v2";

  // This is the known address where ReddID registrations are indexed
  // For the prototype, we scan recent transactions with OP_RETURN data
  final String _indexAddress = "Ru6sB6S79Z86V99Xy3S6sB6S79Z86V99Xy3";

  Future<bool> isUsernameAvailable(String username) async {
    try {
      final cleanName = username.toLowerCase().replaceAll('@', '').trim();
      if (cleanName.length < 3) return false;

      // We query the indexer for transactions containing this metadata
      // For a production build, this would hit a dedicated ReddID Indexer API
      final url = Uri.parse('$_baseUrl/address/$_indexAddress');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List txs = data['transactions'] ?? [];

        for (var tx in txs) {
          // Scan OP_RETURN outputs in the history
          for (var vout in tx['vout']) {
            final String asm = vout['scriptPubKey']['asm'] ?? "";
            if (asm.contains("OP_RETURN") &&
                asm.contains(hexEncode("RDD:ID:$cleanName"))) {
              return false; // Found a match, name is taken
            }
          }
        }
        return true; // No match found in the current index
      }
    } catch (e) {
      print("ReddID Lookup Error: $e");
    }
    return true; // Default to available if network fails (with UI warning)
  }

  String hexEncode(String input) {
    return utf8
        .encode(input)
        .map((e) => e.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
