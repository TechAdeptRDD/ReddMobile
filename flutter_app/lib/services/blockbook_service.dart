import 'dart:convert';
import 'package:http/http.dart' as http;

class BlockbookService {
  final String _baseUrl = "https://blockbook.reddcoin.com/api/v2";

  Future<Map<String, dynamic>> getAddressDetails(String address) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/address/$address'));
      if (response.statusCode == 200) return json.decode(response.body);
    } catch (e) {
      print("Blockbook API Error: $e");
    }
    return {};
  }

  Future<double> getLivePrice() async {
    try {
      final response = await http.get(Uri.parse('https://api.coingecko.com/api/v3/simple/price?ids=reddcoin&vs_currencies=usd'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['reddcoin']['usd'] as num).toDouble();
      }
    } catch (e) {
      print("CoinGecko API Error: $e");
    }
    return 0.0000;
  }

  // Matches DashboardBloc call: blockbookService.getUtxos(...)
  Future<List<dynamic>> getUtxos(String address) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/utxo/$address'));
      if (response.statusCode == 200) return json.decode(response.body) as List<dynamic>;
    } catch (e) {
      print("Blockbook UTXO Error: $e");
    }
    return [];
  }

  // Matches ActivityBloc call: blockbookService.getTransactions(...)
  Future<List<dynamic>> getTransactions(String address) async {
    final details = await getAddressDetails(address);
    return details['transactions'] ?? [];
  }

  // Matches DashboardBloc call: blockbookService.broadcastTransaction(...)
  Future<String> broadcastTransaction(String rawTxHex) async {
    // Mock return until we build the actual POST request to the node
    return "txid_mock_successful_broadcast";
  }
}
