import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();
  static const _keyMnemonic = 'wallet_mnemonic';

  Future<void> saveMnemonic(String mnemonic) async {
    await _storage.write(key: _keyMnemonic, value: mnemonic);
  }

  Future<String?> getMnemonic() async {
    return await _storage.read(key: _keyMnemonic);
  }

  Future<void> deleteMnemonic() async {
    await _storage.delete(key: _keyMnemonic);
  }

  Future<bool> hasWallet() async {
    final mnemonic = await getMnemonic();
    return mnemonic != null && mnemonic.isNotEmpty;
  }
}
