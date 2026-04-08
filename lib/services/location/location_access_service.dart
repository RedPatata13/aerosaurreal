import 'package:app_settings/app_settings.dart';
import 'package:permission_handler/permission_handler.dart';

enum LocationAccessIssue {
  none,
  permissionDenied,
  permissionPermanentlyDenied,
  serviceDisabled,
}

class LocationAccessService {
  static Future<LocationAccessIssue> getIssue({
    bool requestPermission = false,
  }) async {
    final status = requestPermission
        ? await Permission.locationWhenInUse.request()
        : await Permission.locationWhenInUse.status;

    if (status.isGranted) {
      final serviceStatus = await Permission.locationWhenInUse.serviceStatus;
      if (serviceStatus != ServiceStatus.enabled) {
        return LocationAccessIssue.serviceDisabled;
      }
      return LocationAccessIssue.none;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      return LocationAccessIssue.permissionPermanentlyDenied;
    }

    return LocationAccessIssue.permissionDenied;
  }

  static Future<void> openResolution(LocationAccessIssue issue) {
    switch (issue) {
      case LocationAccessIssue.serviceDisabled:
        return AppSettings.openAppSettings(type: AppSettingsType.location);
      case LocationAccessIssue.permissionDenied:
      case LocationAccessIssue.permissionPermanentlyDenied:
        return openAppSettings();
      case LocationAccessIssue.none:
        return Future<void>.value();
    }
  }
}
