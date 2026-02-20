import 'dart:convert';
import 'package:http/http.dart' as http;

class BlockbookService {
  final String baseUrl = 'https://live.reddcoin.com';

  Future<dynamic> _reliableGet(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$endpoint')).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) return json.decode(response.body);
      throw Exception('Failed to load data: ${response.statusCode}');
    } catch (e) {
      print("API Error: $e");
      return null;
    }
  }

  Future<Map<String, dynamic>> getNetworkInfo() async {
    final data = await _reliableGet('/api/v2/');
    return data != null ? data['backend'] ?? {} : {};
  }

  Future<List<dynamic>> getTransactions(String address) async {
    final data = await _reliableGet('/api/v2/address/$address');
    return data != null ? data['transactions'] ?? [] : [];
  }

  Future<double> getLivePrice() async => 0.0001; 
  Future<Map<String, dynamic>> getAddressDetails(String address) async => {};
  Future<List<dynamic>> getUtxos(String address) async => [];
  Future<int> estimateFee({int inputs = 1, int outputs = 2}) async => 10000;
  Future<String> broadcastTransaction(String hex) async => "txid_placeholder";
}
