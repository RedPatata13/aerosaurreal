import '../../models/device.dart';
import '../api/devices_api.dart';
import '../ble/ble_provisioning_service.dart';
import 'device_code_parser.dart';
import 'wifi_service.dart';

class DeviceSetupService {
  final DevicesApi _devicesApi;

  DeviceSetupService(this._devicesApi);

  String normalizeDeviceCode(String raw) {
    return DeviceCodeParser.normalize(raw);
  }

  Future<Device> registerDevice({
    required String rawCode,
    String? name,
  }) async {
    final deviceId = normalizeDeviceCode(rawCode);
    final registered = await _devicesApi.registerDevice(
      deviceId: deviceId,
      name: name,
    );
    return Device.fromApi(registered);
  }

  Future<String?> getSuggestedWifiName() {
    return WifiService.getWifiName();
  }

  Future<void> provisionWifi({
    required String rawCode,
    String? ssid,
    required String pass,
  }) async {
    final deviceId = normalizeDeviceCode(rawCode);
    final wifiName = (ssid ?? '').trim();
    if (wifiName.isEmpty) {
      throw Exception('SSID is required');
    }

    await BleProvisioningService.provisionWifi(
      deviceId: deviceId,
      ssid: wifiName,
      pass: pass,
    );
  }
}
