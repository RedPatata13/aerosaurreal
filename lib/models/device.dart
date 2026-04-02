import 'package:flutter/material.dart';

enum FanSpeed { slow, moderate, fast }

extension FanSpeedX on FanSpeed {
  String toApi() {
    switch (this) {
      case FanSpeed.slow:
        return "SLOW";
      case FanSpeed.moderate:
        return "MODERATE";
      case FanSpeed.fast:
        return "FAST";
    }
  }

  static FanSpeed fromApi(String value) {
    switch (value.toUpperCase()) {
      case "FAST":
        return FanSpeed.fast;
      case "MODERATE":
        return FanSpeed.moderate;
      case "SLOW":
      default:
        return FanSpeed.slow;
    }
  }
}

@immutable
class Device {
  final String id;
  final String name;
  final String? wifiName;
  final bool? isWifiConnected;
  final bool? isOnline;
  final bool isOn;
  final String aqiLabel;
  final int aqiValue;
  final double aqiPercent;
  final Color aqiRingColor;
  final bool smartMode;
  final bool autoAdjustFanSpeed;
  final bool turnOffAutomatically;
  final FanSpeed fanSpeed;

  final String pm25;
  final String pm10;
  final String voc;
  final String temperature;
  final String humidity;
  final bool harmfulGasDetected;

  final List<int> aqiPeak7d;
  final List<int> aqiAverage7d;
  final List<double> purifierUsageHours7d;
  final double totalUsageHours7d;
  final double dailyUsageHours;
  final int timeInGoodOrModeratePercentToday;
  final double directHoursToday;
  final int energySavedPercent;

  const Device({
    required this.id,
    required this.name,
    this.wifiName,
    this.isWifiConnected,
    this.isOnline,
    required this.isOn,
    required this.aqiLabel,
    required this.aqiValue,
    required this.aqiPercent,
    required this.aqiRingColor,
    required this.smartMode,
    required this.autoAdjustFanSpeed,
    required this.turnOffAutomatically,
    required this.fanSpeed,
    required this.pm25,
    required this.pm10,
    required this.voc,
    required this.temperature,
    required this.humidity,
    required this.harmfulGasDetected,
    required this.aqiPeak7d,
    required this.aqiAverage7d,
    required this.purifierUsageHours7d,
    required this.totalUsageHours7d,
    required this.dailyUsageHours,
    required this.timeInGoodOrModeratePercentToday,
    required this.directHoursToday,
    required this.energySavedPercent,
  });

  Device copyWithFromPatch(Map<String, dynamic> patch) {
    return copyWith(
      isOn: patch.containsKey("power") ? patch["power"] as bool : null,
      smartMode: patch.containsKey("smartMode")
          ? patch["smartMode"] as bool
          : null,
      autoAdjustFanSpeed: patch.containsKey("autoAdjust")
          ? patch["autoAdjust"] as bool
          : null,
      turnOffAutomatically: patch.containsKey("autoOff")
          ? patch["autoOff"] as bool
          : null,
      fanSpeed: patch.containsKey("fanSpeed")
          ? FanSpeedX.fromApi(patch["fanSpeed"] as String)
          : null,
    );
  }

  Device copyWith({
    String? id,
    String? name,
    String? wifiName,
    bool? isWifiConnected,
    bool? isOnline,
    bool? isOn,
    String? aqiLabel,
    int? aqiValue,
    double? aqiPercent,
    Color? aqiRingColor,
    bool? smartMode,
    bool? autoAdjustFanSpeed,
    bool? turnOffAutomatically,
    FanSpeed? fanSpeed,
    String? pm25,
    String? pm10,
    String? voc,
    String? temperature,
    String? humidity,
    bool? harmfulGasDetected,
    List<int>? aqiPeak7d,
    List<int>? aqiAverage7d,
    List<double>? purifierUsageHours7d,
    double? totalUsageHours7d,
    double? dailyUsageHours,
    int? timeInGoodOrModeratePercentToday,
    double? directHoursToday,
    int? energySavedPercent,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      wifiName: wifiName ?? this.wifiName,
      isWifiConnected: isWifiConnected ?? this.isWifiConnected,
      isOnline: isOnline ?? this.isOnline,
      isOn: isOn ?? this.isOn,
      aqiLabel: aqiLabel ?? this.aqiLabel,
      aqiValue: aqiValue ?? this.aqiValue,
      aqiPercent: aqiPercent ?? this.aqiPercent,
      aqiRingColor: aqiRingColor ?? this.aqiRingColor,
      smartMode: smartMode ?? this.smartMode,
      autoAdjustFanSpeed: autoAdjustFanSpeed ?? this.autoAdjustFanSpeed,
      turnOffAutomatically: turnOffAutomatically ?? this.turnOffAutomatically,
      fanSpeed: fanSpeed ?? this.fanSpeed,
      pm25: pm25 ?? this.pm25,
      pm10: pm10 ?? this.pm10,
      voc: voc ?? this.voc,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      harmfulGasDetected: harmfulGasDetected ?? this.harmfulGasDetected,
      aqiPeak7d: aqiPeak7d ?? this.aqiPeak7d,
      aqiAverage7d: aqiAverage7d ?? this.aqiAverage7d,
      purifierUsageHours7d: purifierUsageHours7d ?? this.purifierUsageHours7d,
      totalUsageHours7d: totalUsageHours7d ?? this.totalUsageHours7d,
      dailyUsageHours: dailyUsageHours ?? this.dailyUsageHours,
      timeInGoodOrModeratePercentToday:
          timeInGoodOrModeratePercentToday ??
          this.timeInGoodOrModeratePercentToday,
      directHoursToday: directHoursToday ?? this.directHoursToday,
      energySavedPercent: energySavedPercent ?? this.energySavedPercent,
    );
  }

  static Device minimal({required String id, required String name}) {
    return Device(
      id: id,
      name: name,
      wifiName: null,
      isWifiConnected: null,
      isOnline: null,
      isOn: false,
      smartMode: false,
      autoAdjustFanSpeed: false,
      turnOffAutomatically: false,
      fanSpeed: FanSpeed.slow,
      aqiLabel: '—',
      aqiValue: 0,
      aqiPercent: 0.0,
      aqiRingColor: const Color(0xFF9E9E9E),
      pm25: '—',
      pm10: '—',
      voc: '—',
      temperature: '—',
      humidity: '—',
      harmfulGasDetected: false,
      aqiPeak7d: const [0, 0, 0, 0, 0, 0, 0],
      aqiAverage7d: const [0, 0, 0, 0, 0, 0, 0],
      purifierUsageHours7d: const [0, 0, 0, 0, 0, 0, 0],
      totalUsageHours7d: 0.0,
      dailyUsageHours: 0.0,
      timeInGoodOrModeratePercentToday: 0,
      directHoursToday: 0.0,
      energySavedPercent: 0,
    );
  }

  static Device fromApi(Map<String, dynamic> json) {
    final id = (json['deviceId'] ?? json['DeviceId'] ?? json['id'] ?? '')
        .toString();
    final name = (json['name'] ?? id).toString();
    final wifiName = (json['wifiName'] ??
            json['wifiSsid'] ??
            json['ssid'] ??
            json['wifi'])
        ?.toString();

    bool? parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is num) return value != 0;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized.isEmpty) return null;
        if (normalized == 'true' ||
            normalized == 'connected' ||
            normalized == 'online' ||
            normalized == 'active' ||
            normalized == '1') {
          return true;
        }
        if (normalized == 'false' ||
            normalized == 'disconnected' ||
            normalized == 'offline' ||
            normalized == 'inactive' ||
            normalized == '0') {
          return false;
        }
      }
      return null;
    }

    return Device.minimal(
      id: id,
      name: name,
    ).copyWith(
      wifiName: wifiName == null || wifiName.trim().isEmpty ? null : wifiName,
      isWifiConnected: parseBool(
        json['isWifiConnected'] ??
            json['wifiConnected'] ??
            json['connected'],
      ),
      isOnline: parseBool(
        json['isOnline'] ?? json['online'] ?? json['status'],
      ),
    );
  }

  static Color ringColorForAqiCategory(String? category) {
    final c = (category ?? '').toLowerCase();
    if (c == 'good') {
      return const Color(0xFF3AB54A);
    }
    if (c == 'moderate') {
      return const Color(0xFFF4C20D);
    }
    if (c.contains('unhealthy')) {
      return const Color(0xFFEF5350);
    }
    if (c == 'hazardous') {
      return const Color(0xFF8E24AA);
    }

    return const Color(0xFF9E9E9E);
  }

  Device applyLatestReading(Map<String, dynamic> r) {
    final aqi = (r['aqi'] as num?)?.round() ?? 0;
    final category = (r['aqiCategory'] ?? r['aqiLabel'] ?? '—').toString();

    final aqiPct0to100 = (r['aqiPercent'] as num?)?.toDouble();
    final pct = aqiPct0to100 != null ? (aqiPct0to100 / 100.0) : 0.0;

    String fmtNum(dynamic v, {int decimals = 1}) {
      if (v == null) return '—';
      if (v is num) {
        if (decimals == 0) return v.round().toString();
        return v.toStringAsFixed(decimals);
      }
      final parsed = num.tryParse(v.toString());
      if (parsed == null) return '—';
      if (decimals == 0) return parsed.round().toString();
      return parsed.toStringAsFixed(decimals);
    }

    return copyWith(
      aqiValue: aqi,
      aqiLabel: category,
      aqiPercent: pct.clamp(0.0, 1.0),
      aqiRingColor: ringColorForAqiCategory(category),
      pm25: fmtNum(r['pm25'], decimals: 0),
      pm10: fmtNum(r['pm10'], decimals: 0),
      voc: fmtNum(r['vocsPpm'], decimals: 2),
      temperature: fmtNum(r['tempC'], decimals: 1),
      humidity: fmtNum(r['humidity'], decimals: 0),
      harmfulGasDetected: (r['harmfulGasDetected'] as bool?) ?? false,
    );
  }
}
