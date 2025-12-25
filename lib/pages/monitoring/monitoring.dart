import 'package:flutter/material.dart';

import '/../components/aqi_card.dart';
import '/../dialogs/info_dialog.dart';
import '/../models/device.dart';
import 'widgets/monitoring_legend.dart';
import 'widgets/metric_card.dart';
import 'widgets/gas_card.dart';

class Monitoring extends StatelessWidget {
  final Device device;

  const Monitoring({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF1F2228) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF2B2F36)
        : const Color(0xFFE5E7EB);
    final titleColor = isDark
        ? const Color(0xFFF3F4F6)
        : const Color(0xFF111827);
    final bodyColor = isDark
        ? const Color(0xFFB9C0CB)
        : const Color(0xFF4B5563);
    final primary = isDark ? const Color(0xFF415A77) : const Color(0xFF1B263B);

    final titleMedium =
        theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);
    final bodyMedium =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);

    final sectionTitleStyle = titleMedium.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: (titleMedium.fontSize ?? 16) + 1,
      color: titleColor,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AqiCard(
            background: primary,
            titleStyle: titleMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: (titleMedium.fontSize ?? 16) + 1,
            ),
            bodyStyle: bodyMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            onInfo: () => showInfoDialog(
              context,
              title: 'AQI',
              body:
                  'Air Quality Index (AQI) indicates overall air quality on a 0–200 scale.',
            ),
            valueLabel: device.aqiLabel,
            aqiValue: device.aqiValue,
            percent: device.aqiPercent,
            percentText: '${(device.aqiPercent * 100).round()}%',
            ringColor: device.aqiRingColor,
          ),

          const SizedBox(height: 14),
          Text('Reading Status', style: sectionTitleStyle),
          const SizedBox(height: 10),
          const MonitoringLegend(),
          const SizedBox(height: 12),

          MetricCard(
            title: 'PM 2.5',
            value: device.pm25,
            unit: 'µg/m³',
            subtitle: 'Fine Particles',
            color: cardColor,
            borderColor: borderColor,
            titleColor: titleColor,
            bodyColor: bodyColor,
            progress: 0.35,
            progressColor: const Color(0xFF3AB54A),
            onInfo: () => showInfoDialog(
              context,
              title: 'PM2.5',
              body: 'Fine particles that can enter the lungs.',
            ),
          ),

          const SizedBox(height: 10),
          MetricCard(
            title: 'PM 10',
            value: device.pm10,
            unit: 'µg/m³',
            subtitle: 'Coarse Particles',
            color: cardColor,
            borderColor: borderColor,
            titleColor: titleColor,
            bodyColor: bodyColor,
            progress: 0.28,
            progressColor: const Color(0xFF3AB54A),
            onInfo: () => showInfoDialog(
              context,
              title: 'PM10',
              body: 'Larger inhalable particles.',
            ),
          ),

          const SizedBox(height: 10),
          MetricCard(
            title: 'VOCs Level',
            value: device.voc,
            unit: 'ppm',
            subtitle: 'Air Pollutants',
            color: cardColor,
            borderColor: borderColor,
            titleColor: titleColor,
            bodyColor: bodyColor,
            progress: 0.18,
            progressColor: const Color(0xFF3AB54A),
            onInfo: () => showInfoDialog(
              context,
              title: 'VOC',
              body: 'Invisible gases affecting air quality.',
            ),
          ),

          const SizedBox(height: 10),
          GasCard(
            color: cardColor,
            borderColor: borderColor,
            titleColor: titleColor,
            bodyColor: bodyColor,
          ),
        ],
      ),
    );
  }
}
