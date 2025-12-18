import 'package:flutter/material.dart';

enum FanSpeed { slow, moderate, fast }

@immutable
class Device {
  final String id;
  final String name;
  final bool isOn;
  final String aqiLabel;
  final int aqiValue;
  final double aqiPercent;
  final Color aqiRingColor;
  final bool smartMode;
  final bool autoAdjustFanSpeed;
  final bool turnOffAutomatically;
  final FanSpeed fanSpeed;

  // Monitoring demo fields
  final String pm25;
  final String pm10;
  final String voc;

  // Insights demo fields.
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
    required this.aqiPeak7d,
    required this.aqiAverage7d,
    required this.purifierUsageHours7d,
    required this.totalUsageHours7d,
    required this.dailyUsageHours,
    required this.timeInGoodOrModeratePercentToday,
    required this.directHoursToday,
    required this.energySavedPercent,
  });

  Device copyWith({
    String? id,
    String? name,
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
      aqiPeak7d: aqiPeak7d ?? this.aqiPeak7d,
      aqiAverage7d: aqiAverage7d ?? this.aqiAverage7d,
      purifierUsageHours7d: purifierUsageHours7d ?? this.purifierUsageHours7d,
      totalUsageHours7d: totalUsageHours7d ?? this.totalUsageHours7d,
      dailyUsageHours: dailyUsageHours ?? this.dailyUsageHours,
      timeInGoodOrModeratePercentToday: timeInGoodOrModeratePercentToday ??
          this.timeInGoodOrModeratePercentToday,
      directHoursToday: directHoursToday ?? this.directHoursToday,
      energySavedPercent: energySavedPercent ?? this.energySavedPercent,
    );
  }

  static Device demoFromDb({required String id, required String name, int seed = 0}) {
    final presets = <Device>[
      const Device(
        id: 'AV501',
        name: 'Room 301',
        isOn: true,
        aqiLabel: 'Good',
        aqiValue: 75,
        aqiPercent: 0.75,
        aqiRingColor: Color(0xFF3AB54A),
        smartMode: true,
        autoAdjustFanSpeed: true,
        turnOffAutomatically: false,
        fanSpeed: FanSpeed.moderate,
        pm25: '17',
        pm10: '13',
        voc: '0.11',
        aqiPeak7d: [150, 130, 120, 110, 100, 95, 120],
        aqiAverage7d: [120, 110, 100, 95, 85, 80, 105],
        purifierUsageHours7d: [14.4, 9.3, 15.5, 14.4, 2.2, 3.3, 16.5],
        totalUsageHours7d: 71.6,
        dailyUsageHours: 10.2,
        timeInGoodOrModeratePercentToday: 85,
        directHoursToday: 16.5,
        energySavedPercent: 34,
      ),
      const Device(
        id: 'AV502',
        name: 'Room 302',
        isOn: false,
        aqiLabel: 'Moderate',
        aqiValue: 61,
        aqiPercent: 0.61,
        aqiRingColor: Color(0xFFFFC107),
        smartMode: false,
        autoAdjustFanSpeed: false,
        turnOffAutomatically: true,
        fanSpeed: FanSpeed.slow,
        pm25: '20',
        pm10: '72',
        voc: '0.26',
        aqiPeak7d: [150, 135, 120, 115, 110, 100, 105],
        aqiAverage7d: [125, 115, 105, 100, 98, 90, 95],
        purifierUsageHours7d: [14.4, 9.3, 9.5, 15.5, 14.4, 15.2, 14.0],
        totalUsageHours7d: 71.6,
        dailyUsageHours: 10.2,
        timeInGoodOrModeratePercentToday: 61,
        directHoursToday: 14.0,
        energySavedPercent: 25,
      ),
      const Device(
        id: 'AV503',
        name: 'Room 303',
        isOn: true,
        aqiLabel: 'Good',
        aqiValue: 90,
        aqiPercent: 0.90,
        aqiRingColor: Color(0xFF3AB54A),
        smartMode: true,
        autoAdjustFanSpeed: false,
        turnOffAutomatically: true,
        fanSpeed: FanSpeed.fast,
        pm25: '10',
        pm10: '8',
        voc: '0.09',
        aqiPeak7d: [150, 110, 95, 90, 60, 50, 45],
        aqiAverage7d: [110, 95, 80, 65, 50, 40, 35],
        purifierUsageHours7d: [14.4, 9.3, 14.4, 3.5, 3.4, 3.4, 3.3],
        totalUsageHours7d: 44.0,
        dailyUsageHours: 6.3,
        timeInGoodOrModeratePercentToday: 90,
        directHoursToday: 3.3,
        energySavedPercent: 65,
      ),
    ];

    final base = presets[seed % presets.length];
    return base.copyWith(id: id, name: name);
  }
}
