class Transaction {
  final String txid;
  final int amount;
  final int confirmations;
  final DateTime timestamp;

  Transaction({
    required this.txid,
    required this.amount,
    required this.confirmations,
    required this.timestamp,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['value'] ?? json['amount'] ?? 0;
    final rawTimestamp = json['blockTime'] ?? json['time'] ?? 0;

    final timestampInt = _parseInt(rawTimestamp);
    final parsedAmount = _parseInt(rawAmount);

    return Transaction(
      txid: json['txid']?.toString() ?? '',
      amount: parsedAmount,
      confirmations: _parseInt(json['confirmations']),
      timestamp: _parseTimestamp(timestampInt),
    );
  }

  factory Transaction.fromBlockbookJson(
    Map<String, dynamic> json,
    String walletAddress,
  ) {
    final int incoming = _sumVoutForAddress(json['vout'], walletAddress);
    final int outgoing = _sumVinForAddress(json['vin'], walletAddress);
    final rawTimestamp = json['blockTime'] ?? json['time'] ?? 0;
    final timestampInt = _parseInt(rawTimestamp);

    return Transaction(
      txid: json['txid']?.toString() ?? '',
      amount: incoming - outgoing,
      confirmations: _parseInt(json['confirmations']),
      timestamp: _parseTimestamp(timestampInt),
    );
  }

  static int _sumVinForAddress(dynamic vin, String address) {
    if (vin is! List) return 0;

    var total = 0;
    for (final input in vin) {
      if (input is! Map<String, dynamic>) continue;
      final addresses = _extractAddresses(input);
      if (addresses.contains(address)) {
        total += _parseInt(input['value']);
      }
    }
    return total;
  }

  static int _sumVoutForAddress(dynamic vout, String address) {
    if (vout is! List) return 0;

    var total = 0;
    for (final output in vout) {
      if (output is! Map<String, dynamic>) continue;
      final addresses = _extractAddresses(output);
      if (addresses.contains(address)) {
        total += _parseInt(output['value']);
      }
    }
    return total;
  }

  static Set<String> _extractAddresses(Map<String, dynamic> entry) {
    final Set<String> addresses = {};

    final directAddresses = entry['addresses'];
    if (directAddresses is List) {
      for (final addr in directAddresses) {
        if (addr != null) {
          addresses.add(addr.toString());
        }
      }
    }

    final directAddress = entry['addr'];
    if (directAddress != null) {
      addresses.add(directAddress.toString());
    }

    final scriptPubKey = entry['scriptPubKey'];
    if (scriptPubKey is Map<String, dynamic>) {
      final scriptAddresses = scriptPubKey['addresses'];
      if (scriptAddresses is List) {
        for (final addr in scriptAddresses) {
          if (addr != null) {
            addresses.add(addr.toString());
          }
        }
      }
    }

    return addresses;
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '0') ?? 0;
  }

  static DateTime _parseTimestamp(int timestampInt) {
    final isMilliseconds = timestampInt > 9999999999;
    return isMilliseconds
        ? DateTime.fromMillisecondsSinceEpoch(timestampInt)
        : DateTime.fromMillisecondsSinceEpoch(timestampInt * 1000);
  }
}
