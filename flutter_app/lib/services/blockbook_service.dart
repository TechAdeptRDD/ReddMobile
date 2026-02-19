import 'dart:convert';
import 'package:http/http.dart' as http;

class BlockbookService {
  // The Redundant Node Array
  final List<String> _baseUrls = [
    'https://blockbook.reddcoin.com',
    'https://live.reddcoin.com/api', // Fallback explorer API
    // We can easily add more community nodes here in the future
  ];

  // Helper method to ping nodes in order until one responds
  Future<http.Response> _reliableGet(String path) async {
    for (String url in _baseUrls) {
      try {
        final res = await http.get(
          Uri.parse('$url$path'),
          headers: {'User-Agent': 'ReddMobile-V1'},
        ).timeout(const Duration(seconds: 5)); // 5-second timeout per node

        if (res.statusCode == 200) return res;
      } catch (e) {
        print("Node failed: $url. Trying next fallback...");
        continue;
      }
    }
    throw Exception("All network nodes are currently unreachable.");
  }

  // 1. Get Address Details (Balance & History)
  Future<Map<String, dynamic>> getAddressDetails(String address) async {
    final res = await _reliableGet('/api/v2/address/$address');
    return json.decode(res.body);
  }

  // 2. Get UTXOs (Unspent Transaction Outputs)
  Future<List<dynamic>> getUtxos(String address) async {
    final res = await _reliableGet('/api/v2/utxo/$address');
    return json.decode(res.body);
  }

  // 3. Broadcast Signed Transaction (Uses POST, so we implement the same fallback logic)
  Future<String> broadcastTransaction(String signedHex) async {
    for (String url in _baseUrls) {
      try {
        final res = await http.post(
          Uri.parse('$url/api/v2/sendtx/'),
          headers: {
            'Content-Type': 'text/plain',
            'User-Agent': 'ReddMobile-V1'
          },
          body: signedHex,
        ).timeout(const Duration(seconds: 8)); // Slightly longer timeout for broadcasts

        if (res.statusCode == 200) {
          final data = json.decode(res.body);
          if (data['result'] != null) return data['result']; // Returns the TXID
        } else {
          final errorData = json.decode(res.body);
          throw Exception("Broadcast rejected: ${errorData['error']}");
        }
      } catch (e) {
        if (e.toString().contains("Broadcast rejected")) rethrow; // If the node actively rejected it, don't try others
        continue; // Otherwise, try the next node
      }
    }
    throw Exception("Failed to connect to the Reddcoin network for broadcast.");
  }

  // 4. Get Global Network Activity (For the Social Feed)
  // 5. Estimate Network Fee
  Future<int> estimateFee() async {
    try {
      final res = await _reliableGet("/api/v2/estimatefee/2");
      final data = json.decode(res.body);
      if (data["result"] != null) {
        double rddPerKb = double.parse(data["result"]);
        int sats = (rddPerKb * 100000000).toInt();
        return sats > 100000 ? sats : 100000; // Floor of 0.001 RDD
      }
    } catch (_) { }
    return 100000; // Safe Fallback
  }

  Future<List<dynamic>> getRecentTransactions() async {
    final res = await _reliableGet('/api/v2/block/last'); // Fetch latest block
    final blockData = json.decode(res.body);
    
    // Fallback logic to grab the previous block if the latest is empty
    if (blockData['txs'] == null || blockData['txs'].isEmpty) {
        final prevBlockHash = blockData['previousBlockHash'];
        if (prevBlockHash != null) {
            final prevRes = await _reliableGet('/api/v2/block/$prevBlockHash');
            final prevBlockData = json.decode(prevRes.body);
            return prevBlockData['txs'] ?? [];
        }
    }
    return blockData['txs'] ?? [];
  }
}
