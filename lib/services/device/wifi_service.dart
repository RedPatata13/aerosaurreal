import 'package:network_info_plus/network_info_plus.dart';

import '../location/location_access_service.dart';

class WifiService {
  static Future<String?> getWifiName() async {
    final issue = await LocationAccessService.getIssue();
    if (issue != LocationAccessIssue.none) {
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
