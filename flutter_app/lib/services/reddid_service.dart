import 'dart:convert';
import 'package:http/http.dart' as http;

class ReddIDService {
  static const String _baseUrl = "https://blockbook.reddcoin.com/api/v2";
  static const Duration _timeout = Duration(seconds: 10);

  // This is the known address where ReddID registrations are indexed
  // For the prototype, we scan recent transactions with OP_RETURN data
  final String _indexAddress = "Ru6sB6S79Z86V99Xy3S6sB6S79Z86V99Xy3";

  Future<bool> isUsernameAvailable(String username) async {
    try {
      final cleanName = username.toLowerCase().replaceAll('@', '').trim();
      if (!RegExp(r'^[a-z0-9_]{3,32}$').hasMatch(cleanName)) return false;

      // We query the indexer for transactions containing this metadata
      // For a production build, this would hit a dedicated ReddID Indexer API
      final url = Uri.parse('$_baseUrl/address/$_indexAddress');
      if (url.scheme != 'https') return false;

      final response = await http
          .get(url, headers: const {'Accept': 'application/json'})
          .timeout(_timeout);

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
    } on Exception {
      // Intentionally swallow transport/parsing errors to avoid leaking internals.
    }
    return false;
  }

  String hexEncode(String input) {
    return utf8
        .encode(input)
        .map((e) => e.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
