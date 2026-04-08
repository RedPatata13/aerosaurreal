import 'package:flutter/material.dart';
import '../../components/offline_status_banner.dart';
import '/../../models/device.dart';
import '/../components/aqi_card.dart';
import '../home/dialogs/info_dialog.dart';
import 'widgets/monitoring_legend.dart';
import 'widgets/metric_card.dart';
import 'widgets/gas_card.dart';

class Monitoring extends StatelessWidget {
  final Device device;
  final Future<void> Function() onRefresh;

  const Monitoring({super.key, required this.device, required this.onRefresh});

  double _parseNum(String v) => double.tryParse(v) ?? 0;

  ({double progress, Color color}) _pm25Bar(double v) {
    const safeMax = 12.0;
    const unhealthyMax = 35.4;
    const moderateMax = 55.4;

    Color color;
    double progress;

    if (v <= safeMax) {
      color = const Color(0xFF3AB54A);
      progress = (v / safeMax) * 0.25;
    } else if (v <= unhealthyMax) {
      color = const Color(0xFFF4C20D);
      progress = 0.25 + ((v - safeMax) / (unhealthyMax - safeMax)) * 0.25;
    } else if (v <= moderateMax) {
      color = const Color(0xFFFF9800);
      progress =
          0.50 + ((v - unhealthyMax) / (moderateMax - unhealthyMax)) * 0.25;
    } else {
      color = const Color(0xFFEF5350);
      progress = 0.75 + ((v - moderateMax) / moderateMax) * 0.25;
    }

    return (progress: progress.clamp(0.0, 1.0), color: color);
  }

  ({double progress, Color color}) _pm10Bar(double v) {
    const safeMax = 54.0;
    const unhealthyMax = 154.0;
    const moderateMax = 254.0;

    Color color;
    double progress;

    if (v <= safeMax) {
      color = const Color(0xFF3AB54A);
      progress = (v / safeMax) * 0.25;
    } else if (v <= unhealthyMax) {
      color = const Color(0xFFF4C20D);
      progress = 0.25 + ((v - safeMax) / (unhealthyMax - safeMax)) * 0.25;
    } else if (v <= moderateMax) {
      color = const Color(0xFFFF9800);
      progress =
          0.50 + ((v - unhealthyMax) / (moderateMax - unhealthyMax)) * 0.25;
    } else {
      color = const Color(0xFFEF5350);
      progress = 0.75 + ((v - moderateMax) / moderateMax) * 0.25;
    }

    return (progress: progress.clamp(0.0, 1.0), color: color);
  }

  ({double progress, Color color}) _vocBar(double v) {
    const safeMax = 0.3;
    const unhealthyMax = 1.0;
    const moderateMax = 3.0;

    Color color;
    double progress;

    if (v <= safeMax) {
      color = const Color(0xFF3AB54A);
      progress = (v / safeMax) * 0.25;
    } else if (v <= unhealthyMax) {
      color = const Color(0xFFF4C20D);
      progress = 0.25 + ((v - safeMax) / (unhealthyMax - safeMax)) * 0.25;
    } else if (v <= moderateMax) {
      color = const Color(0xFFFF9800);
      progress =
          0.50 + ((v - unhealthyMax) / (moderateMax - unhealthyMax)) * 0.25;
    } else {
      color = const Color(0xFFEF5350);
      progress = 0.75 + ((v - moderateMax) / moderateMax) * 0.25;
    }

    return (progress: progress.clamp(0.0, 1.0), color: color);
  }

  ({double progress, Color color}) _tempBar(double v) {
    const coldMin = 10.0;
    const comfyMin = 18.0;
    const comfyMax = 30.0;
    const hotMax = 40.0;

    Color color;
    double progress;

    if (v <= comfyMin) {
      color = const Color(0xFF3AB54A);
      progress = ((v - coldMin) / (comfyMin - coldMin)) * 0.33;
    } else if (v <= comfyMax) {
      color = const Color(0xFFF4C20D);
      progress = 0.33 + ((v - comfyMin) / (comfyMax - comfyMin)) * 0.33;
    } else {
      color = const Color(0xFFEF5350);
      progress = 0.66 + ((v - comfyMax) / (hotMax - comfyMax)) * 0.34;
    }

    return (progress: progress.clamp(0.0, 1.0), color: color);
  }

  ({double progress, Color color}) _humidityBar(double v) {
    const low = 30.0;
    const ideal = 60.0;
    const high = 80.0;

    Color color;
    double progress;

    if (v <= low) {
      color = const Color(0xFFFF9800);
      progress = (v / low) * 0.33;
    } else if (v <= ideal) {
      color = const Color(0xFF3AB54A);
      progress = 0.33 + ((v - low) / (ideal - low)) * 0.33;
    } else {
      color = const Color(0xFFEF5350);
      progress = 0.66 + ((v - ideal) / (high - ideal)) * 0.34;
    }

    return (progress: progress.clamp(0.0, 1.0), color: color);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final pm25Val = _parseNum(device.pm25);
    final pm10Val = _parseNum(device.pm10);
    final vocVal = _parseNum(device.voc);
    final tempVal = _parseNum(device.temperature);
    final humVal = _parseNum(device.humidity);
    final pm25Bar = _pm25Bar(pm25Val);
    final pm10Bar = _pm10Bar(pm10Val);
    final vocBar = _vocBar(vocVal);
    final tempBar = _tempBar(tempVal);
    final humBar = _humidityBar(humVal);

    final titleMedium =
        theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);
    final bodyMedium =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OfflineStatusBanner(device: device),
            AqiCard(
              background: theme.colorScheme.primary,
              titleStyle: titleMedium.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
                fontSize: (titleMedium.fontSize ?? 16) + 1,
              ),
              bodyStyle: bodyMedium.copyWith(
                color: theme.colorScheme.onPrimary.withOpacity(0.9),
              ),
              onInfo: () => showInfoDialog(
                context,
                title: 'AQI',
                body:
                    'Air Quality Index (AQI) indicates overall air quality on a 0–300 scale.',
              ),
              valueLabel: device.aqiLabel,
              aqiValue: device.aqiValue,
              percent: device.aqiPercent,
              percentText: '${(device.aqiPercent * 100).round()}%',
              ringColor: device.aqiRingColor,
            ),

            const SizedBox(height: 14),
            Text(
              'Reading Status',
              style: (theme.textTheme.titleMedium ?? const TextStyle())
                  .copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) + 1,
                    color: theme.colorScheme.onSurface,
                  ),
            ),
            const SizedBox(height: 10),
            const MonitoringLegend(),
            const SizedBox(height: 12),

            // PM2.5
            MetricCard(
              title: 'PM 2.5',
              value: device.pm25,
              unit: 'µg/m³',
              subtitle: 'Fine Particles',
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderColor: theme.dividerColor,
              titleColor: theme.colorScheme.onSurface,
              bodyColor: theme.colorScheme.onSurface.withOpacity(0.7),
              progress: pm25Bar.progress,
              progressColor: pm25Bar.color,
              onInfo: () => showInfoDialog(
                context,
                title: 'PM2.5',
                body:
                    'These are tiny particles about 30 times smaller than the width of a human hair. They can stay in the air for hours and reach deep into the lungs.',
              ),
            ),

            const SizedBox(height: 10),
            // PM10
            MetricCard(
              title: 'PM 10',
              value: device.pm10,
              unit: 'µg/m³',
              subtitle: 'Coarse Particles',
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderColor: theme.dividerColor,
              titleColor: theme.colorScheme.onSurface,
              bodyColor: theme.colorScheme.onSurface.withOpacity(0.7),
              progress: pm10Bar.progress,
              progressColor: pm10Bar.color,
              onInfo: () => showInfoDialog(
                context,
                title: 'PM10',
                body:
                    'PM10 particles include dust, pollen, and smoke which are small enough to be inhaled into the respiratory system.',
              ),
            ),

            const SizedBox(height: 10),
            // VOC
            MetricCard(
              title: 'VOCs Level',
              value: device.voc,
              unit: 'ppm',
              subtitle: 'Air Pollutants',
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderColor: theme.dividerColor,
              titleColor: theme.colorScheme.onSurface,
              bodyColor: theme.colorScheme.onSurface.withOpacity(0.7),
              progress: vocBar.progress,
              progressColor: vocBar.color,
              onInfo: () => showInfoDialog(
                context,
                title: 'VOC',
                body:
                    'VOCs are invisible gases released from products like paints, cleaners, or furniture. At high levels they can irritate your eyes, nose, and throat.',
              ),
            ),

            // Temperature
            const SizedBox(height: 10),
            MetricCard(
              title: 'Temperature',
              value: device.temperature,
              unit: '°C',
              subtitle: 'Room Heat Level',
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderColor: theme.dividerColor,
              titleColor: theme.colorScheme.onSurface,
              bodyColor: theme.colorScheme.onSurface.withOpacity(0.7),
              progress: tempBar.progress,
              progressColor: tempBar.color,
              onInfo: () => showInfoDialog(
                context,
                title: 'Temperature',
                body:
                    'Temperature shows how hot or cold the environment is. Higher temperatures can make indoor air feel stuffy and worsen comfort.',
              ),
            ),

            //Humidity
            const SizedBox(height: 10),
            MetricCard(
              title: 'Humidity',
              value: device.humidity,
              unit: '%',
              subtitle: 'Moisture Level',
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderColor: theme.dividerColor,
              titleColor: theme.colorScheme.onSurface,
              bodyColor: theme.colorScheme.onSurface.withOpacity(0.7),
              progress: humBar.progress,
              progressColor: humBar.color,
              onInfo: () => showInfoDialog(
                context,
                title: 'Humidity',
                body:
                    'Humidity is the amount of moisture in the air. Too low feels dry (irritates skin/throat), too high can feel sticky and may encourage mold growth.',
              ),
            ),

            const SizedBox(height: 10),
            GasCard(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderColor: theme.dividerColor,
              titleColor: theme.colorScheme.onSurface,
              bodyColor: theme.colorScheme.onSurface.withOpacity(0.7),
              harmfulGasDetected: device.harmfulGasDetected,
            ),
          ],
        ),
      ),
    );
  }
}
