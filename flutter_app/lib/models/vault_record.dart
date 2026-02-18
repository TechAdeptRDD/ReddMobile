enum VaultRecordType {
  oauthToken,
  secureNote,
  contactProfile,
  custom,
}

class VaultRecord {
  const VaultRecord({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    required this.encryptedPayload,
  });

  final String id;
  final VaultRecordType type;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String encryptedPayload;

  factory VaultRecord.fromJson(Map<String, dynamic> json) {
    return VaultRecord(
      id: json['id'] as String,
      type: _vaultRecordTypeFromString(json['type'] as String),
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      encryptedPayload: json['encryptedPayload'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'encryptedPayload': encryptedPayload,
    };
  }

  static VaultRecordType _vaultRecordTypeFromString(String value) {
    return VaultRecordType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => VaultRecordType.custom,
    );
  }
}
