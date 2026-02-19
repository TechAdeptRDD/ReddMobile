import 'dart:convert';
import 'package:http/http.dart' as http;

class PulseService {
  final String _baseUrl = "https://live.reddcoin.com/api/v2";

  // 1. Fetch Network Health Metrics
  Future<Map<String, dynamic>> getNetworkSnapshot() async {
    try {
      final res = await http.get(Uri.parse("$_baseUrl/info"));
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        return {
          "difficulty": data["difficulty"] ?? "0.0",
          "blocks": data["blocks"] ?? 0,
          "version": data["version"] ?? "v4.2.x",
          "isStaking": true, // Placeholder for network-wide PoSV status
        };
      }
    } catch (e) {
      print("Pulse Error (Network): $e");
    }
    return {"difficulty": "N/A", "blocks": 0, "version": "N/A"};
  }

  // 2. Fetch Global Social Memos (The Pulse)
  Future<List<Map<String, String>>> getGlobalPulse() async {
    try {
      // In a production scenario, we'd query a specific indexer for OP_RETURN payloads.
      // For now, we fetch recent transactions and parse the metadata.
      final res = await http.get(Uri.parse("$_baseUrl/txs?limit=20"));
      if (res.statusCode == 200) {
        final List txs = json.decode(res.body)["txs"];
        List<Map<String, String>> pulses = [];
        
        for (var tx in txs) {
          // Look for RDD:ID or Tip Memos in the OP_RETURN outputs
          for (var out in tx["vout"]) {
            if (out["asm"] != null && out["asm"].startsWith("OP_RETURN")) {
              String hex = out["asm"].replaceAll("OP_RETURN ", "");
              String message = _decodeHex(hex);
              if (message.contains("RDD:")) {
                pulses.add({
                  "txid": tx["txid"],
                  "message": message,
                  "value": tx["valueOut"].toString(),
                });
              }
            }
          }
        }
        return pulses;
      }
    } catch (e) {
      print("Pulse Error (Social): $e");
    }
    return [];
  }

  String _decodeHex(String hex) {
    try {
      List<int> bytes = [];
      for (int i = 0; i < hex.length; i += 2) {
        bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
      }
      return utf8.decode(bytes);
    } catch (_) { return "Encrypted Payload"; }
  }
}
