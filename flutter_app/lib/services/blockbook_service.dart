import 'dart:convert';
import 'package:http/http.dart' as http;

class BlockbookService {
  final String baseUrl = "https://live.reddcoin.com/api/v2";

  // Check if a ReddID handle is already taken
  Future<bool> isHandleAvailable(String handle) async {
    try {
      // In Reddcoin, handles are usually registered to a specific 'Namespace' address.
      // We search for transactions containing the OP_RETURN handle string.
      final response = await http.get(Uri.parse("$baseUrl/search/$handle"));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // If the API returns transactions or owners for this handle, it's taken.
        return data['results'] == null || (data['results'] as List).isEmpty;
      }
      return true; // Assume available if search fails (policy decision)
    } catch (e) {
      return true;
    }
  }

  Future<List<dynamic>> getTransactions(String address) async {
    final response = await http.get(Uri.parse("$baseUrl/address/$address"));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["transactions"] ?? [];
    }
    throw Exception("Failed to load transactions");
  }

  Future<List<dynamic>> getUtxos(String address) async {
    final response = await http.get(Uri.parse("$baseUrl/utxo/$address"));
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception("Failed to load UTXOs");
  }

  Future<String> broadcastTransaction(String hex) async {
    final response = await http.post(
      Uri.parse("$baseUrl/sendtx"),
      body: hex,
    );
    if (response.statusCode == 200) return jsonDecode(response.body)['result'];
    throw Exception("Broadcast failed: ${response.body}");
  }
}
