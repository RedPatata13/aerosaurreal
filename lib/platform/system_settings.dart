import 'dart:io';

import 'package:flutter/services.dart';

class SystemSettings {
  static const MethodChannel _channel =
      MethodChannel('com.example.aerosaur_2nd_sem/system_settings');

  static Future<void> openWifiSettings() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('openWifiSettings');
  }
}

