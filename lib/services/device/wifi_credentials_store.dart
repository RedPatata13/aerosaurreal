import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SavedWifiCredentials {
  final String ssid;
  final String password;

  const SavedWifiCredentials({
    required this.ssid,
    required this.password,
  });
}

class WifiCredentialsStore {
  static const _ssidKey = 'saved_wifi_ssid';
  static const _passwordKey = 'saved_wifi_password';

  final FlutterSecureStorage _storage;

  const WifiCredentialsStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  Future<void> save({
    required String ssid,
    required String password,
  }) async {
    await _storage.write(key: _ssidKey, value: ssid);
    await _storage.write(key: _passwordKey, value: password);
  }

  Future<SavedWifiCredentials?> read() async {
    final ssid = await _storage.read(key: _ssidKey);
    final password = await _storage.read(key: _passwordKey);

    if (ssid == null ||
        ssid.trim().isEmpty ||
        password == null ||
        password.isEmpty) {
      return null;
    }

    return SavedWifiCredentials(ssid: ssid, password: password);
  }

  Future<void> clear() async {
    await _storage.delete(key: _ssidKey);
    await _storage.delete(key: _passwordKey);
  }
}
