import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final titleMedium =
        theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);
    final bodyMedium =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);

    final sectionTitleStyle = titleMedium.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: (titleMedium.fontSize ?? 16) + 1,
      color: theme.colorScheme.onSurface,
    );

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                    'Air Quality Index (AQI) indicates overall air quality on a 0–200 scale.',
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

            MetricCard(
              title: 'PM 2.5',
              value: device.pm25,
              unit: 'µg/m³',
              subtitle: 'Fine Particles',
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderColor: theme.dividerColor,
              titleColor: theme.colorScheme.onSurface,
              bodyColor: theme.colorScheme.onSurface.withOpacity(0.7),
              progress: 0.35,
              progressColor: const Color(0xFF3AB54A),
              onInfo: () => showInfoDialog(
                context,
                title: 'PM2.5',
                body:
                    'These are tiny particles about 30 times smaller than the width of a human hair. They can stay in the air for hours and reach deep into the lungs, affecting breathing and overall health',
              ),
            ),

            const SizedBox(height: 10),
            MetricCard(
              title: 'PM 10',
              value: device.pm10,
              unit: 'µg/m³',
              subtitle: 'Coarse Particles',
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderColor: theme.dividerColor,
              titleColor: theme.colorScheme.onSurface,
              bodyColor: theme.colorScheme.onSurface.withOpacity(0.7),
              progress: 0.28,
              progressColor: const Color(0xFF3AB54A),
              onInfo: () => showInfoDialog(
                context,
                title: 'PM10',
                body:
                    'PM10 particles are about one-seventh the width of a human hair. They include dust, pollen, and smoke which are small enough to be inhaled into the respiratory system.',
              ),
            ),

            const SizedBox(height: 10),
            MetricCard(
              title: 'VOCs Level',
              value: device.voc,
              unit: 'ppm',
              subtitle: 'Air Pollutants',
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderColor: theme.dividerColor,
              titleColor: theme.colorScheme.onSurface,
              bodyColor: theme.colorScheme.onSurface.withOpacity(0.7),
              progress: 0.18,
              progressColor: const Color(0xFF3AB54A),
              onInfo: () => showInfoDialog(
                context,
                title: 'VOC',
                body:
                    'VOCs are invisible gases released from products like paints, cleaners, or furniture. You can’t see them, but at high levels they can irritate your eyes, nose, and throat and worsen indoor air quality.',
              ),
            ),

            const SizedBox(height: 10),
            GasCard(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderColor: theme.dividerColor,
              titleColor: theme.colorScheme.onSurface,
              bodyColor: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ],
        ),
      ),
    );
  }
}
