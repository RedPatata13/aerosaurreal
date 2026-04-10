import 'dart:async';
import 'dart:convert';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class BleProvisioningService {
  static final Guid serviceUuid = Guid('6e400001-b5a3-f393-e0a9-e50e24dcca9e');
  static final Guid wifiCharUuid = Guid('6e400002-b5a3-f393-e0a9-e50e24dcca9e');
  static final Guid ackCharUuid = Guid('6e400003-b5a3-f393-e0a9-e50e24dcca9e');

  static Future<void> _ensurePermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final denied = statuses.entries
        .where((entry) => !entry.value.isGranted)
        .map((entry) => entry.key.toString().split('.').last)
        .toList(growable: false);

    if (denied.isNotEmpty) {
      throw Exception('Missing required permissions: ${denied.join(', ')}.');
    }
  }

  static String _normalize(String value) {
    return value.trim().toUpperCase();
  }

  static bool _matchesDeviceId({
    required String deviceId,
    required ScanResult result,
  }) {
    final target = _normalize(deviceId);
    final candidates = <String>{
      result.device.platformName,
      result.device.advName,
      result.advertisementData.advName,
    };

    return candidates.any((value) => _normalize(value).contains(target));
  }

  static bool _advertisesProvisioningService(ScanResult result) {
    return result.advertisementData.serviceUuids.any(
      (uuid) => uuid == serviceUuid,
    );
  }

  static Future<void> provisionWifi({
    required String deviceId,
    required String ssid,
    required String pass,
  }) async {
    await _ensurePermissions();

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      throw Exception('Bluetooth is off. Turn it on and try again.');
    }

    await FlutterBluePlus.stopScan();

    BluetoothDevice? device;
    ScanResult? serviceMatch;
    final completer = Completer<void>();

    final sub = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        if (_matchesDeviceId(deviceId: deviceId, result: result) &&
            !completer.isCompleted) {
          device = result.device;
          FlutterBluePlus.stopScan();
          completer.complete();
          break;
        }

        if (serviceMatch == null && _advertisesProvisioningService(result)) {
          serviceMatch = result;
        }
      }
    });

    await FlutterBluePlus.startScan(
      timeout: const Duration(seconds: 12),
    );

    await completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        final fallback = serviceMatch;
        if (fallback != null && !completer.isCompleted) {
          device = fallback.device;
          completer.complete();
        }
      },
    );

    await sub.cancel();
    await FlutterBluePlus.stopScan();

    if (device == null) {
      throw Exception(
        'BLE device not found. Ensure the ESP32 is in provisioning mode and advertising nearby.',
      );
    }

    await device!.connect(timeout: const Duration(seconds: 12));

    try {
      final services = await device!.discoverServices();

      final svc = services.firstWhere(
        (s) => s.uuid == serviceUuid,
        orElse: () => throw Exception('Service not found after connect'),
      );

      final wifiChar = svc.characteristics.firstWhere(
        (c) => c.uuid == wifiCharUuid,
        orElse: () => throw Exception('WiFi characteristic not found'),
      );

      final ackChar = svc.characteristics.firstWhere(
        (c) => c.uuid == ackCharUuid,
        orElse: () => throw Exception('ACK characteristic not found'),
      );

      await ackChar.setNotifyValue(true);

      final ackCompleter = Completer<Map<String, dynamic>>();

      final ackSub = ackChar.onValueReceived.listen((value) {
        if (!ackCompleter.isCompleted) {
          try {
            ackCompleter.complete(jsonDecode(utf8.decode(value)));
          } catch (_) {
            ackCompleter.completeError(Exception('Bad ACK JSON'));
          }
        }
      });

      final payload = jsonEncode({
        'deviceId': deviceId,
        'ssid': ssid,
        'pass': pass,
      });

      await wifiChar.write(utf8.encode(payload), withoutResponse: false);

      final ack = await ackCompleter.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('ACK timeout: no response from device'),
      );

      await ackSub.cancel();

      if (ack['ok'] != true) {
        throw Exception('Provision failed: ${ack['err']}');
      }
    } finally {
      await device!.disconnect();
    }
  }
}
