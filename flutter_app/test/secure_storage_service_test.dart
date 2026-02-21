import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:redd_mobile/services/secure_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureStorageService contact QA flows', () {
    test('migrates legacy contacts key and preserves handles', () async {
      FlutterSecureStorage.setMockInitialValues({
        'saved_contacts': jsonEncode(['Alice', '@Bob']),
      });
      final service = SecureStorageService();

      final migrated = await service.getContacts();

      expect(migrated, [
        {'handle': 'Alice', 'cid': ''},
        {'handle': '@Bob', 'cid': ''},
      ]);

      final secondRead = await service.getContacts();
      expect(secondRead.length, 2);
    });

    test('normalizes handles and updates CID without duplicates', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final service = SecureStorageService();

      await service.addContact(' @TechaDept ');
      await service.addContact('techadept', cid: 'ipfs://avatarCID');

      final contacts = await service.getContacts();

      expect(contacts, [
        {'handle': 'techadept', 'cid': 'ipfs://avatarCID'},
      ]);
    });
  });
}
