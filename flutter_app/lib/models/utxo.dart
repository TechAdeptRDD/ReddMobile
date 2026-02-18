class Utxo {
  final String txid;
  final int vout;
  final int amount; // in Satoshis/Satoshi-equivalent

  Utxo({
    required this.txid,
    required this.vout,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
    'txid': txid,
    'vout': vout,
    'amount': amount,
  };

  factory Utxo.fromJson(Map<String, dynamic> json) {
    return Utxo(
      txid: json['txid'] ?? '',
      vout: json['vout'] ?? 0,
      amount: int.tryParse(json['value'] ?? '0') ?? (json['amount'] ?? 0),
    );
  }
}
