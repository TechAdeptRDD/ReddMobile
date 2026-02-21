import 'dart:convert';
import 'package:http/http.dart' as http;

class BlockbookService {
  static const String _baseUrl = 'https://blockbook.reddcoin.com';
  static const Duration _timeout = Duration(seconds: 10);

  Uri _buildUri(String endpoint) {
    final uri = Uri.parse('$_baseUrl$endpoint');
    if (uri.scheme != 'https') {
      throw const FormatException('Insecure protocol is not allowed.');
    }
    return uri;
  }

  Future<dynamic> _reliableGet(String endpoint) async {
    try {
      final response = await http
          .get(_buildUri(endpoint), headers: const {'Accept': 'application/json'})
          .timeout(_timeout);
      if (response.statusCode != 200 || response.body.isEmpty) return null;
      return json.decode(response.body);
    } on FormatException {
      return null;
    } on http.ClientException {
      return null;
    } on Exception {
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
