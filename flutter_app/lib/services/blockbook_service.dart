import 'dart:convert';
import 'package:http/http.dart' as http;

class BlockbookService {
  final String baseUrl = 'https://live.reddcoin.com';

  Future<dynamic> _reliableGet(String endpoint) async {
    final response = await http.get(Uri.parse('$baseUrl$endpoint'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load data');
  }

  Future<List<dynamic>> getTransactions(String address) async {
    try {
      final data = await _reliableGet('/api/v2/address/$address');
      return data['transactions'] ?? [];
    } catch (e) {
      return [];
    }
  }

  Future<double> getLivePrice() async {
    return 0.0001; // Placeholder for CoinGecko API integration
  }
}
