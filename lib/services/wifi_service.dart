import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class WifiService {
  static Future<String?> getWifiName() async {
    final status = await Permission.locationWhenInUse.request();
    if (!status.isGranted) {
      return null;
    }

    final info = NetworkInfo();

    try {
      final name = await info.getWifiName();

      if (name == null || name == '<unknown ssid>') {
        return null;
      }

      return name.replaceAll('"', '');
    } catch (_) {
      return null;
    }
  }
}
