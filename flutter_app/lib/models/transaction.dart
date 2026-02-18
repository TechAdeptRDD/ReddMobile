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

    final timestampInt = rawTimestamp is int
        ? rawTimestamp
        : int.tryParse(rawTimestamp.toString()) ?? 0;

    final parsedAmount = rawAmount is int
        ? rawAmount
        : int.tryParse(rawAmount.toString()) ?? 0;

    final isMilliseconds = timestampInt > 9999999999;

    return Transaction(
      txid: json['txid']?.toString() ?? '',
      amount: parsedAmount,
      confirmations: json['confirmations'] is int
          ? json['confirmations']
          : int.tryParse(json['confirmations']?.toString() ?? '0') ?? 0,
      timestamp: isMilliseconds
          ? DateTime.fromMillisecondsSinceEpoch(timestampInt)
          : DateTime.fromMillisecondsSinceEpoch(timestampInt * 1000),
    );
  }
}
