import '../../models/device.dart';
import '../api/devices_api.dart';
import '../ble/ble_provisioning_service.dart';
import 'device_code_parser.dart';
import 'wifi_service.dart';
import 'wifi_credentials_store.dart';

class DeviceSetupService {
  final DevicesApi _devicesApi;
  final WifiCredentialsStore _wifiCredentialsStore;

  DeviceSetupService(
    this._devicesApi, {
    WifiCredentialsStore? wifiCredentialsStore,
  }) : _wifiCredentialsStore =
           wifiCredentialsStore ?? const WifiCredentialsStore();

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

  Future<SavedWifiCredentials?> getSavedCredentials() {
    return _wifiCredentialsStore.read();
  }

  Future<SavedWifiCredentials?> getSavedCredentialsForCurrentWifi() async {
    final ssid = await getSuggestedWifiName();
    if (ssid == null || ssid.isEmpty) {
      return null;
    }

    final saved = await _wifiCredentialsStore.read();
    if (saved == null) {
      return null;
    }

    if (saved.ssid != ssid) {
      return null;
    }

    return saved;
  }

  Future<void> saveCurrentWifiPassword(String password) async {
    final ssid = await getSuggestedWifiName();
    if (ssid == null || ssid.isEmpty) {
      throw Exception('Connect your phone to Wi-Fi first.');
    }
    if (password.isEmpty) {
      throw Exception('Wi-Fi password is required.');
    }

    await _wifiCredentialsStore.save(ssid: ssid, password: password);
  }

  Future<void> saveWifiCredentials({
    required String ssid,
    required String password,
  }) async {
    final trimmedSsid = ssid.trim();
    if (trimmedSsid.isEmpty) {
      throw Exception('SSID is required.');
    }
    if (password.isEmpty) {
      throw Exception('Wi-Fi password is required.');
    }

    await _wifiCredentialsStore.save(ssid: trimmedSsid, password: password);
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

  Future<void> autoProvisionIfPossible({
    required String rawCode,
  }) async {
    final currentWifi = await getSuggestedWifiName();
    if (currentWifi == null || currentWifi.isEmpty) {
      throw Exception('Connect your phone to Wi-Fi first.');
    }

    final saved = await getSavedCredentialsForCurrentWifi();
    if (saved == null) {
      throw Exception('Wi-Fi password not saved for $currentWifi.');
    }

    await provisionWifi(
      rawCode: rawCode,
      ssid: saved.ssid,
      pass: saved.password,
    );
  }
}
