import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();

  // --- Wallet Keys ---
  Future<void> saveMnemonic(String mnemonic) async {
    await _storage.write(key: 'wallet_mnemonic', value: mnemonic);
  }

  Future<String?> getMnemonic() async {
    return await _storage.read(key: 'wallet_mnemonic');
  }

  // --- Address Book / Contacts ---
  Future<void> saveContacts(List<String> contacts) async {
    await _storage.write(key: 'saved_contacts', value: jsonEncode(contacts));
  }

  Future<List<String>> getContacts() async {
    final data = await _storage.read(key: 'saved_contacts');
    if (data == null) return [];
    try {
      return List<String>.from(jsonDecode(data));
    } catch (e) {
      return [];
    }
  }

  Future<void> addContact(String handle) async {
    final contacts = await getContacts();
    final cleanHandle = handle.toLowerCase().replaceAll('@', '').trim();
    if (!contacts.contains(cleanHandle)) {
      contacts.add(cleanHandle);
      await saveContacts(contacts);
    }
  }
}
