import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

class SecureStorageInvalidatedException implements Exception {
  final String message;

  const SecureStorageInvalidatedException(this.message);

  @override
  String toString() => message;
}

class SecureStorageService {
  String? _cachedFiatPreference;
  static const AndroidOptions _androidOptions =
      AndroidOptions(encryptedSharedPreferences: true, resetOnError: true);
  static final IOSOptions _iosOptions = const IOSOptions(
    accessibility: KeychainAccessibility.passcode,

    synchronizable: false,
  );

  final _storage = const FlutterSecureStorage(
    aOptions: _androidOptions,
    iOptions: _iosOptions,
  );

  // --- Wallet Keys ---
  Future<void> saveMnemonic(String mnemonic) async {
    await _writeCriticalValue('wallet_mnemonic', mnemonic.trim());
  }

  Future<String?> getMnemonic() async {
    return _readCriticalValue('wallet_mnemonic');
  }

  Future<void> deleteMnemonic() async {
    await _storage.delete(key: 'wallet_mnemonic');
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
    final normalizedCurrency = currency.trim().toLowerCase();
    _cachedFiatPreference = normalizedCurrency;
    await _storage.write(key: 'fiat_pref', value: normalizedCurrency);
  }

  Future<String> getFiatPreference() async {
    final cached = _cachedFiatPreference;
    if (cached != null && cached.isNotEmpty) return cached;

    final persisted = (await _storage.read(key: 'fiat_pref'))?.trim().toLowerCase();
    final resolved = (persisted == null || persisted.isEmpty) ? 'usd' : persisted;
    _cachedFiatPreference = resolved;
    return resolved;
  }

  Future<void> removeContact(String handle) async {
    final contacts = await getContacts();
    contacts.removeWhere((c) => c['handle'] == handle);
    await saveContacts(contacts);
  }

  // --- Lightweight network cache ---
  Future<void> writeCacheValue(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> readCacheValue(String key) async {
    return _storage.read(key: key);
  }

  Future<void> deleteCacheValue(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> _writeCriticalValue(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } on PlatformException catch (e) {
      throw SecureStorageInvalidatedException(
        'Failed to write secure value for $key: ${e.code}',
      );
    }
  }

  Future<String?> _readCriticalValue(String key) async {
    try {
      return await _storage.read(key: key);
    } on PlatformException catch (e) {
      // Device security state changed (e.g. passcode removed), treat as invalidated.
      await _storage.delete(key: key);
      throw SecureStorageInvalidatedException(
        'Secure value for $key is no longer accessible: ${e.code}',
      );
    }
  }
}
