import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleProvisioningService {
  static final Guid serviceUuid = Guid("6e400001-b5a3-f393-e0a9-e50e24dcca9e");
  static final Guid wifiCharUuid = Guid("6e400002-b5a3-f393-e0a9-e50e24dcca9e");
  static final Guid ackCharUuid = Guid("6e400003-b5a3-f393-e0a9-e50e24dcca9e");

  static Future<void> _ensurePermissions() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.locationWhenInUse.request();
  }

  static Future<void> provisionWifi({
    required String deviceId,
    required String ssid,
    required String pass,
  }) async {
    await _ensurePermissions();

    final targetName = "AEROSAUR-$deviceId";
    BluetoothDevice? device;

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));

    final sub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final name = r.device.platformName;
        if (name == targetName) {
          device = r.device;
          FlutterBluePlus.stopScan();
          break;
        }
      }
    });

    await Future.delayed(const Duration(seconds: 10));
    await sub.cancel();
    await FlutterBluePlus.stopScan();

    if (device == null) {
      throw Exception(
        "BLE device not found. Ensure ESP32 is in provisioning mode.",
      );
    }

    await device!.connect(timeout: const Duration(seconds: 12));

    try {
      final services = await device!.discoverServices();
      final svc = services.firstWhere((s) => s.uuid == serviceUuid);

      final wifiChar = svc.characteristics.firstWhere(
        (c) => c.uuid == wifiCharUuid,
      );
      final ackChar = svc.characteristics.firstWhere(
        (c) => c.uuid == ackCharUuid,
      );

      await ackChar.setNotifyValue(true);

      String? ackMessage;
      final ackSub = ackChar.onValueReceived.listen((value) {
        ackMessage = utf8.decode(value);
      });

      final payload = jsonEncode({
        "deviceId": deviceId,
        "ssid": ssid,
        "pass": pass,
      });

      await wifiChar.write(utf8.encode(payload), withoutResponse: false);

      await Future.delayed(const Duration(seconds: 2));
      await ackSub.cancel();

      if (ackMessage != null) {
        try {
          final parsed = jsonDecode(ackMessage!);
          final ok = parsed["ok"] == true;
          if (!ok) {
            throw Exception("Provision failed: ${parsed["err"]}");
          }
        } catch (_) {}
      }
    } finally {
      await device!.disconnect();
    }
  }
}
