import 'package:flutter_test/flutter_test.dart';
import 'package:redd_mobile/services/blockbook_service.dart';

void main() {
  group('Blockbook API Integration Tests', () {
    late BlockbookService blockbookService;

    setUp(() {
      blockbookService = BlockbookService();
    });

    test('1. Fetch UTXOs from a known live address', () async {
      // The official Reddcoin Project Dev Fund address (usually has UTXOs)
      const testAddress = 'Rmhzj1f9DmyzQnXZKnrXz4F2J2rMrcNf6K';
      
      try {
        final utxos = await blockbookService.getUtxos(testAddress);
        
        // We just want to prove the network call succeeds and parses the list
        expect(utxos, isA<List<Utxo>>());
        
        if (utxos.isNotEmpty) {
          print('✅ Successfully fetched ${utxos.length} UTXOs.');
          print('Sample TXID: ${utxos.first.txid}');
          print('Sample Value (Satoshis): ${utxos.first.value}');
          
          expect(utxos.first.txid.isNotEmpty, true);
          expect(utxos.first.value.isNotEmpty, true);
        } else {
          print('⚠️ Address has 0 UTXOs right now, but API connection succeeded.');
        }
      } catch (e) {
        fail('Network call failed: $e');
      }
    });
  });
}
