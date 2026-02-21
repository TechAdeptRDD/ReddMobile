import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileResolverService {
  static const String _baseUrl = "https://blockbook.reddcoin.com/api/v2";
  static const Duration _timeout = Duration(seconds: 10);

  // The global index address we defined earlier to track all registrations
  final String _indexAddress = "Ru6sB6S79Z86V99Xy3S6sB6S79Z86V99Xy3";

  /// Scans the blockchain and resolves a @handle into a real address and avatar CID
  Future<Map<String, String>?> resolveUsername(String username) async {
    try {
      final cleanName = username.toLowerCase().replaceAll('@', '').trim();
      if (!RegExp(r'^[a-z0-9_]{3,32}$').hasMatch(cleanName)) return null;

      final endpoint = Uri.parse('$_baseUrl/address/$_indexAddress');
      if (endpoint.scheme != 'https') return null;

      final response = await http
          .get(endpoint, headers: const {'Accept': 'application/json'})
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List txs = data['transactions'] ?? [];

        // Search the ledger history for this specific identity claim
        for (var tx in txs) {
          for (var vout in tx['vout']) {
            final String asm = vout['scriptPubKey']['asm'] ?? "";

            // Check if this transaction contains our OP_RETURN protocol
            if (asm.contains("OP_RETURN") &&
                asm.contains(hexEncode("RDD:ID:$cleanName:"))) {
              final parts = _extractPayloadParts(asm);
              if (parts == null) continue;

              final vins = tx['vin'];
              if (vins is! List || vins.isEmpty) continue;
              final senderAddresses = vins[0]['addresses'];
              if (senderAddresses is! List || senderAddresses.isEmpty) continue;

              // Protocol Format: RDD:ID:username:cid
              return {
                'address': senderAddresses[0].toString(),
                'cid': parts[3],
              };
            }
          }
        }
      }
    } on Exception {
      // Avoid propagating internals to callers/UI.
    }
    return null; // Identity not found on-chain
  }

  List<String>? _extractPayloadParts(String asm) {
    final payload = asm.split('OP_RETURN ');
    if (payload.length < 2 || payload[1].isEmpty) return null;

    final decoded = hexDecode(payload[1]);
    final parts = decoded.split(':');
    if (parts.length < 4 || parts[0] != 'RDD' || parts[1] != 'ID') {
      return null;
    }

    return parts;
  }

  String hexEncode(String input) {
    return utf8
        .encode(input)
        .map((e) => e.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  String hexDecode(String hex) {
    String result = "";
    for (int i = 0; i < hex.length; i += 2) {
      try {
        String part = hex.substring(i, i + 2);
        result += String.fromCharCode(int.parse(part, radix: 16));
      } catch (_) {
        continue; // Skip invalid hex blocks
      }
    }
    return result;
  }
}
