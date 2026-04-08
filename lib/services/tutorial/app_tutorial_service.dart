import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AppTutorialService {
  AppTutorialService([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  static const String _homeTourSeenKey = 'home_feature_tour_seen';

  final FlutterSecureStorage _storage;

  Future<bool> hasSeenHomeTour() async {
    return await _storage.read(key: _homeTourSeenKey) == 'true';
  }

  Future<void> markHomeTourSeen() {
    return _storage.write(key: _homeTourSeenKey, value: 'true');
  }
}
