import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const AndroidOptions _androidOptions =
      AndroidOptions(encryptedSharedPreferences: true);
  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  final _storage = const FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );

  // --- Wallet Keys ---
  Future<void> saveMnemonic(String mnemonic) async {
    await _storage.write(key: 'wallet_mnemonic', value: mnemonic);
  }

  Future<String?> getMnemonic() async {
    return _storage.read(key: 'wallet_mnemonic');
  }

  // --- Avatar-Rich Address Book ---
  Future<void> saveContacts(List<Map<String, String>> contacts) async {
    await _storage.write(key: 'saved_contacts_v2', value: jsonEncode(contacts));
  }

  Future<List<Map<String, String>>> getContacts() async {
    final data = await _storage.read(key: 'saved_contacts_v2');
    if (data == null) {
      // Migration fallback from v1 text-only contacts
      final oldData = await _storage.read(key: 'saved_contacts');
      if (oldData != null) {
        try {
          final List<String> oldList = List<String>.from(jsonDecode(oldData));
          final migrated =
              oldList.map((handle) => {'handle': handle, 'cid': ''}).toList();
          await saveContacts(migrated);
          await _storage.delete(key: 'saved_contacts'); // Clean up old key
          return migrated;
        } catch (_) {
          return [];
        }
      }
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(data);
      return decoded.map((e) => Map<String, String>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addContact(String handle, {String cid = ''}) async {
    final contacts = await getContacts();
    final cleanHandle = handle.toLowerCase().replaceAll('@', '').trim();

    // Check if user already exists
    int index = contacts.indexWhere((c) => c['handle'] == cleanHandle);
    if (index != -1) {
      // Update CID if they added an avatar later
      if (cid.isNotEmpty && contacts[index]['cid'] != cid) {
        contacts[index]['cid'] = cid;
        await saveContacts(contacts);
      }
    } else {
      contacts.add({'handle': cleanHandle, 'cid': cid});
      await saveContacts(contacts);
    }
  }

  // --- Localization ---
  Future<void> saveFiatPreference(String currency) async {
    await _storage.write(key: 'fiat_pref', value: currency);
  }

  Future<String> getFiatPreference() async {
    return _storage.read(key: 'fiat_pref') ?? 'usd';
  }

  Future<void> removeContact(String handle) async {
    final contacts = await getContacts();
    contacts.removeWhere((c) => c['handle'] == handle);
    await saveContacts(contacts);
  }
}
