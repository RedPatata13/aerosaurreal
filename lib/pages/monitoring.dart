import 'package:flutter/material.dart';

import '../components/aqi_card.dart';
import '../components/info_dialog.dart';
import '../models/device.dart';

class Monitoring extends StatelessWidget {
  final Device device;

  const Monitoring({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF1F2228) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2B2F36) : const Color(0xFFE5E7EB);
    final titleColor = isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827);
    final bodyColor = isDark ? const Color(0xFFB9C0CB) : const Color(0xFF4B5563);
    final primary = isDark ? const Color(0xFF415A77) : const Color(0xFF1B263B);

    final titleMedium = theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);
    final bodyMedium = theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
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
                  'Air Quality Index (AQI) indicates overall air quality on a 0–200 scale, where 0 is excellent and 200 is very unhealthy. Higher values mean cleaner air.',
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
            style: sectionTitleStyle,
          ),
          const SizedBox(height: 10),
          const _Legend(),
          const SizedBox(height: 12),
          _MetricCard(
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
              title: 'PM2.5 (Fine Particulate Matter)',
              body:
                  'These are tiny particles about 30 times smaller than the width of a human hair. They can stay in the air for hours and can enter the lungs, affecting breathing and overall health.',
            ),
          ),
          const SizedBox(height: 10),
          _MetricCard(
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
              title: 'PM10 (Coarse Particulate Matter)',
              body:
                  'PM10 particles are about one‑seventh the width of a human hair. They can be inhaled and may irritate the respiratory system.',
            ),
          ),
          const SizedBox(height: 10),
          _MetricCard(
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
              title: 'VOC (Volatile Organic Compounds)',
              body:
                  'VOCs are invisible gases released from products like paint, cleaners, or furniture. You can’t see them, but at high levels they can irritate your eyes, nose, and throat and worsen indoor air quality.',
            ),
          ),
          const SizedBox(height: 10),
          _GasCard(
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

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: const Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 140,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child:
                        _LegendItem(label: 'Safe', color: Color(0xFF3AB54A)),
                  ),
                ),
                SizedBox(width: 26),
                SizedBox(
                  width: 140,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _LegendItem(
                      label: 'Moderate',
                      color: Color(0xFFFF9800),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 140,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _LegendItem(
                      label: 'Unhealthy',
                      color: Color(0xFFFFC107),
                    ),
                  ),
                ),
                SizedBox(width: 26),
                SizedBox(
                  width: 140,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _LegendItem(
                      label: 'Dangerous',
                      color: Color(0xFFE53935),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? const Color(0xFFB9C0CB) : const Color(0xFF4B5563);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String subtitle;
  final Color color;
  final Color borderColor;
  final Color titleColor;
  final Color bodyColor;
  final double progress;
  final Color progressColor;
  final VoidCallback onInfo;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.subtitle,
    required this.color,
    required this.borderColor,
    required this.titleColor,
    required this.bodyColor,
    required this.progress,
    required this.progressColor,
    required this.onInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.air, size: 16, color: titleColor),
              const SizedBox(width: 6),
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: onInfo,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: EdgeInsets.all(2.0),
                  child: Icon(Icons.info_outline, size: 16, color: titleColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                unit,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(color: bodyColor),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: borderColor.withValues(alpha: 0.9),
              color: progressColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _GasCard extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final Color titleColor;
  final Color bodyColor;

  const _GasCard({
    required this.color,
    required this.borderColor,
    required this.titleColor,
    required this.bodyColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 16, color: titleColor),
              const SizedBox(width: 6),
              Text(
                'Harmful Gases',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF3AB54A).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Not Detected',
                style: TextStyle(
                  color: Color(0xFF3AB54A),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.center,
            child: Text(
              'Air is safe from harmful gases.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: bodyColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
