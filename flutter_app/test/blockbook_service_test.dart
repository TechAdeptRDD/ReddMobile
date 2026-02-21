import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:redd_mobile/services/blockbook_service.dart';
import 'package:redd_mobile/services/secure_storage_service.dart';

class _InMemoryStorage extends SecureStorageService {
  final Map<String, String> _cache = {};

  @override
  Future<void> writeCacheValue(String key, String value) async {
    _cache[key] = value;
  }

  @override
  Future<String?> readCacheValue(String key) async {
    return _cache[key];
  }

  @override
  Future<void> deleteCacheValue(String key) async {
    _cache.remove(key);
  }
}

void main() {
  test('retries after rate limiting and succeeds', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      if (calls == 1) {
        return http.Response('', 429);
      }
      return http.Response(json.encode({'backend': {'chain': 'reddcoin'}}), 200);
    });

    final service = BlockbookService(
      httpClient: client,
      secureStorageService: _InMemoryStorage(),
    );

    final data = await service.getNetworkInfo();

    expect(data['chain'], 'reddcoin');
    expect(calls, 2);
  });

  test('falls back to cached address data when network fails', () async {
    final storage = _InMemoryStorage();

    final primeService = BlockbookService(
      httpClient: MockClient(
        (_) async => http.Response(
          json.encode({
            'balance': '100000000',
            'transactions': [
              {'txid': 'abc'}
            ]
          }),
          200,
        ),
      ),
      secureStorageService: storage,
    );

    final first = await primeService.getAddressDetails('RTestAddress');
    expect(first['balance'], '100000000');

    final offlineService = BlockbookService(
      httpClient: MockClient((_) async => throw const http.ClientException('offline')),
      secureStorageService: storage,
    );

    final cached = await offlineService.getAddressDetails('RTestAddress');
    expect(cached['balance'], '100000000');
    expect((cached['transactions'] as List).length, 1);
  });


  test('parses decimal fee response to satoshis per kb', () async {
    final service = BlockbookService(
      httpClient: MockClient((request) async {
        if (request.url.path.contains('/estimatefee/1')) {
          return http.Response(json.encode({'result': '0.00012000'}), 200);
        }
        return http.Response('{}', 200);
      }),
      secureStorageService: _InMemoryStorage(),
    );

    final fee = await service.estimateFee(inputs: 1, outputs: 2);

    expect(fee, 28);
  });

  test('throws detailed error when node rejects broadcast', () async {
    final service = BlockbookService(
      httpClient: MockClient(
        (_) async => http.Response(
          json.encode({
            'error': {'message': 'mempool min fee not met'}
          }),
          400,
        ),
      ),
      secureStorageService: _InMemoryStorage(),
    );

    expect(
      () => service.broadcastTransaction('deadbeef'),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('mempool min fee not met'),
        ),
      ),
    );
  });

}
