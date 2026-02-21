import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'secure_storage_service.dart';

class BlockbookService {
  static const String _baseUrl = 'https://blockbook.reddcoin.com';
  static const Duration _timeout = Duration(seconds: 10);
  static const int _maxRetries = 3;
  static const Duration _baseRetryDelay = Duration(milliseconds: 400);
  static const Duration _networkInfoTtl = Duration(minutes: 5);
  static const Duration _addressCacheTtl = Duration(minutes: 2);
  static const int _fallbackFeePerKbSats = 10000;
  static const int _satsPerCoin = 100000000;

  final http.Client _client;
  final SecureStorageService _storage;
  final Random _random;

  final Map<String, Future<dynamic>> _inflightGets = {};

  BlockbookService({
    http.Client? httpClient,
    SecureStorageService? secureStorageService,
    Random? random,
  })  : _client = httpClient ?? http.Client(),
        _storage = secureStorageService ?? SecureStorageService(),
        _random = random ?? Random();

  Uri _buildUri(String endpoint) {
    final uri = Uri.parse('$_baseUrl$endpoint');
    if (uri.scheme != 'https') {
      throw const FormatException('Insecure protocol is not allowed.');
    }
    return uri;
  }

  String _cacheKey(String prefix, String key) => 'network_cache_${prefix}_$key';

  Future<Map<String, dynamic>?> _readCachedMap(String key, Duration ttl) async {
    final raw = await _storage.readCacheValue(key);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.tryParse(decoded['cachedAt'] as String? ?? '');
      final payload = decoded['payload'];
      if (cachedAt == null || payload is! Map<String, dynamic>) return null;
      if (DateTime.now().difference(cachedAt) > ttl) return null;
      return payload;
    } catch (_) {
      await _storage.deleteCacheValue(key);
      return null;
    }
  }

  Future<void> _writeCachedMap(String key, Map<String, dynamic> payload) async {
    final wrapped = json.encode({'cachedAt': DateTime.now().toIso8601String(), 'payload': payload});
    await _storage.writeCacheValue(key, wrapped);
  }

  Future<dynamic> _reliableGet(
    String endpoint, {
    int maxRetries = _maxRetries,
  }) async {
    // Deduplicate concurrent requests for the same endpoint to avoid thundering-herd
    // behavior when multiple blocs/screens refresh at once.
    final existing = _inflightGets[endpoint];
    if (existing != null) return existing;

    final request = _reliableGetInternal(endpoint, maxRetries: maxRetries);
    _inflightGets[endpoint] = request;

    try {
      return await request;
    } finally {
      _inflightGets.remove(endpoint);
    }
  }

  Future<dynamic> _reliableGetInternal(String endpoint, {int maxRetries = _maxRetries}) async {
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await _client
            .get(_buildUri(endpoint), headers: const {'Accept': 'application/json'})
            .timeout(_timeout);

        if (response.statusCode == 429) {
          if (attempt == maxRetries) return null;
          await Future.delayed(_backoffDelay(attempt));
          continue;
        }

        if (response.statusCode >= 500) {
          if (attempt == maxRetries) return null;
          await Future.delayed(_backoffDelay(attempt));
          continue;
        }

        if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
          return null;
        }

        return json.decode(utf8.decode(response.bodyBytes));
      } on TimeoutException {
        if (attempt == maxRetries) return null;
        await Future.delayed(_backoffDelay(attempt));
      } on FormatException {
        return null;
      } on http.ClientException {
        if (attempt == maxRetries) return null;
        await Future.delayed(_backoffDelay(attempt));
      } on Exception {
        if (attempt == maxRetries) return null;
        await Future.delayed(_backoffDelay(attempt));
      }
    }

    return null;
  }

  Duration _backoffDelay(int attempt) {
    final exponentialMs = _baseRetryDelay.inMilliseconds * pow(2, attempt).toInt();
    final jitterMs = _random.nextInt(250);
    return Duration(milliseconds: exponentialMs + jitterMs);
  }

  Future<Map<String, dynamic>> getNetworkInfo() async {
    final key = _cacheKey('network', 'info');
    final cached = await _readCachedMap(key, _networkInfoTtl);
    if (cached != null) return cached;

    final data = await _reliableGet('/api/v2/');
    final backend = data is Map<String, dynamic> ? (data['backend'] as Map<String, dynamic>? ?? {}) : {};
    if (backend.isNotEmpty) {
      await _writeCachedMap(key, backend);
    }
    return backend;
  }

  Future<List<dynamic>> getTransactions(String address) async {
    final data = await getAddressDetails(address);
    return data['transactions'] as List<dynamic>? ?? [];
  }

  Future<double> getLivePrice() async => 0.0001;

  Future<Map<String, dynamic>> getAddressDetails(String address) async {
    final key = _cacheKey('address', address);
    final cached = await _readCachedMap(key, _addressCacheTtl);

    final data = await _reliableGet('/api/v2/address/$address');
    if (data is Map<String, dynamic>) {
      await _writeCachedMap(key, data);
      return data;
    }

    return cached ?? {};
  }

  Future<List<dynamic>> getUtxos(String address) async {
    final data = await _reliableGet('/api/v2/utxo/$address');
    if (data is List<dynamic>) {
      return data;
    }
    return [];
  }

  Future<int> estimateFee({int inputs = 1, int outputs = 2}) async {
    final data = await _reliableGet('/api/v2/estimatefee/1');
    final feePerKb = (data is Map<String, dynamic>) ? _parseFeePerKbSats(data['result']) : null;
    final normalizedFeePerKb = feePerKb ?? _fallbackFeePerKbSats;

    final txSizeBytes = (inputs * 148) + (outputs * 34) + 10;
    return ((normalizedFeePerKb * txSizeBytes) / 1000).ceil();
  }

  int? _parseFeePerKbSats(dynamic rawFee) {
    // Blockbook fee responses can vary by backend: sat/kB integer, decimal coin amount,
    // or numeric strings. Normalize aggressively so fee estimation remains resilient.
    if (rawFee is num) {
      if (rawFee <= 0) return null;

      if (rawFee >= 1) {
        return rawFee.toInt();
      }

      return (rawFee * _satsPerCoin).ceil();
    }

    if (rawFee is! String || rawFee.trim().isEmpty) return null;

    final trimmed = rawFee.trim();
    final asInt = int.tryParse(trimmed);
    if (asInt != null && asInt > 0) {
      return asInt;
    }

    final asDouble = double.tryParse(trimmed);
    if (asDouble != null && asDouble > 0) {
      return asDouble >= 1 ? asDouble.toInt() : (asDouble * _satsPerCoin).ceil();
    }

    return null;
  }

  Future<String> broadcastTransaction(String hex) async {
    final response = await _client
        .post(
          _buildUri('/api/v2/sendtx/'),
          headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: json.encode({'hex': hex}),
        )
        .timeout(_timeout);

    if (response.bodyBytes.isEmpty) {
      throw const FormatException('Broadcast rejected: empty node response.');
    }

    final decoded = json.decode(utf8.decode(response.bodyBytes));
    if (response.statusCode != 200) {
      throw Exception('Broadcast failed (${response.statusCode}): ${_extractNodeError(decoded)}');
    }

    if (decoded is Map<String, dynamic> && decoded['result'] is String) {
      return decoded['result'] as String;
    }

    throw Exception('Broadcast failed: malformed response body.');
  }

  String _extractNodeError(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final error = decoded['error'];
      if (error is String && error.isNotEmpty) return error;
      if (error is Map<String, dynamic>) {
        final message = error['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    }
    return 'Unknown node error';
  }

  void dispose() {
    _client.close();
  }
}
