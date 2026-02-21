import 'dart:convert';
import 'package:http/http.dart' as http;

/// PulseService: The social and technical heartbeat of ReddMobile.
///
/// This service decodes OP_RETURN metadata from the Reddcoin blockchain.
/// RDD Specs (2026):
/// - OP_RETURN Limit: 80 bytes.
/// - Character Filtering: Ensures only printable ASCII is displayed in the Social Pulse.
/// - Consensus Logic: Provides data-hooks for PoSV v2 (Proof of Stake Velocity).
class PulseService {
  static const String _baseUrl = "https://blockbook.reddcoin.com/api/v2";
  static const Duration _timeout = Duration(seconds: 10);

  // Decodes OP_RETURN hex to UTF-8 and filters non-printable control characters
  String _decodeSocialMessage(String hexData) {
    try {
      List<int> bytes = [];
      for (int i = 0; i < hexData.length; i += 2) {
        int byte = int.parse(hexData.substring(i, i + 2), radix: 16);
        // Empathy Filter: Only allow printable characters (32-126)
        // to prevent UI corruption from binary payloads.
        if (byte >= 32 && byte <= 126) bytes.add(byte);
      }
      return utf8.decode(bytes);
    } catch (_) {
      return "Encrypted or Binary Payload";
    }
  }

  Future<List<Map<String, String>>> getGlobalPulse() async {
    try {
      final endpoint = Uri.parse("$_baseUrl/txs?limit=20");
      if (endpoint.scheme != 'https') return [];

      final res = await http
          .get(endpoint, headers: const {'Accept': 'application/json'})
          .timeout(_timeout);
      if (res.statusCode == 200) {
        final List txs = json.decode(res.body)["txs"];
        List<Map<String, String>> pulses = [];
        for (var tx in txs) {
          for (var out in tx["vout"]) {
            if (out["asm"] != null && out["asm"].startsWith("OP_RETURN")) {
              String hex = out["asm"].replaceAll("OP_RETURN ", "");
              String message = _decodeSocialMessage(hex);
              if (message.isNotEmpty &&
                  message != "Encrypted or Binary Payload") {
                pulses.add({
                  "txid": tx["txid"].toString(),
                  "message": message,
                  "value": tx["valueOut"].toString(),
                });
              }
            }
          }
        }
        return pulses;
      }
    } on Exception {
      // Fail closed and keep UI stable.
    }
    return [];
  }
}
