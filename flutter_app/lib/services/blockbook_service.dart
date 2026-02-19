import 'dart:convert';
import 'package:http/http.dart' as http;

class BlockbookService {
  // Official Reddcoin Blockbook URL
  final String _baseUrl = "https://blockbook.reddcoin.com/api/v2";

  /// Fetches the live balance and transaction history for an address
  Future<Map<String, dynamic>> getAddressDetails(String address) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/address/$address'));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print("Blockbook API Error: $e");
    }
    return {};
  }

  /// Fetches the live RDD to USD price
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
    return 0.0000; // Fallback
  }
}
