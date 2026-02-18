import 'dart:convert';

import 'package:http/http.dart' as http;

class BlockbookService {
  BlockbookService({http.Client? client}) : _client = client ?? http.Client();

  static const String _baseUrl = 'https://blockbook.reddcoin.com/api/v2';
  final http.Client _client;

  Future<dynamic> getUtxos(String rddAddress) async {
    final uri = Uri.parse('$_baseUrl/utxo/$rddAddress');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch UTXOs (${response.statusCode}).');
    }

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getAddressInfo(String rddAddress) async {
    final uri = Uri.parse('$_baseUrl/address/$rddAddress');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch address info (${response.statusCode}).');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<String> broadcastTransaction(String signedTxHex) async {
    final uri = Uri.parse('$_baseUrl/sendtx/$signedTxHex');
    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to broadcast transaction (${response.statusCode}): ${response.body}',
      );
    }

    final responseData = jsonDecode(response.body);
    if (responseData is Map<String, dynamic>) {
      final txid = responseData['result'] ?? responseData['txid'];
      if (txid is String && txid.isNotEmpty) {
        return txid;
      }
    }

    throw Exception('Transaction broadcast response missing txid: ${response.body}');
  }

  void dispose() {
    _client.close();
  }
}
