import 'package:flutter/material.dart';

import '/../models/device.dart';
import 'insight_card.dart';
import 'charts/dual_bar_chart.dart';
import 'charts/single_bar_chart.dart';
import 'widgets/legend_dot.dart';
import 'widgets/range_label.dart';
import 'widgets/stat_pill.dart';
import 'widgets/simple_stat_card.dart';

class Insights extends StatelessWidget {
  final Device device;

  const Insights({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleColor = isDark
        ? const Color(0xFFF3F4F6)
        : const Color(0xFF111827);
    final bodyColor = isDark
        ? const Color(0xFFB9C0CB)
        : const Color(0xFF4B5563);
    final cardColor = isDark ? const Color(0xFF1F2228) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF2B2F36)
        : const Color(0xFFE5E7EB);

    const graphPrimary = Color(0xFF415A77);
    const graphSecondary = Color(0xFFA8AFBA);

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
        children: [
          InsightCard(
            title: 'Air Quality Index Trend',
            color: cardColor,
            borderColor: borderColor,
            titleStyle: sectionTitleStyle,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const LegendDot(color: graphSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Peak AQI',
                      style: bodyMedium.copyWith(
                        color: bodyColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const LegendDot(color: graphPrimary),
                    const SizedBox(width: 6),
                    Text(
                      'Average AQI',
                      style: bodyMedium.copyWith(
                        color: bodyColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                DualBarChart(
                  peak: device.aqiPeak7d,
                  avg: device.aqiAverage7d,
                  maxValue: 150,
                  height: 140,
                  peakColor: graphSecondary,
                  avgColor: graphPrimary,
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Expanded(
                      child: RangeLabel(label: 'Good', range: '(0-50)'),
                    ),
                    Expanded(
                      child: RangeLabel(label: 'Moderate', range: '(51-100)'),
                    ),
                    Expanded(
                      child: RangeLabel(
                        label: 'Unhealthy',
                        range: '(101 - 150)',
                      ),
                    ),
                    Expanded(
                      child: RangeLabel(label: 'Dangerous', range: '(150+)'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          InsightCard(
            title: 'Purifier Usage - Over 7 Days',
            color: cardColor,
            borderColor: borderColor,
            titleStyle: sectionTitleStyle,
            child: Column(
              children: [
                const SizedBox(height: 10),
                SingleBarChart(
                  values: device.purifierUsageHours7d,
                  maxValue: 16.5,
                  height: 160,
                  barColor: graphPrimary,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StatPill(
                      label: 'Total Usage',
                      value: '${device.totalUsageHours7d.toStringAsFixed(1)}h',
                      background: isDark
                          ? const Color(0xFF2B2F36)
                          : const Color(0xFFF3F4F6),
                      textColor: titleColor,
                      subColor: bodyColor,
                    ),
                    const SizedBox(width: 10),
                    StatPill(
                      label: 'Daily Usage',
                      value: '${device.dailyUsageHours.toStringAsFixed(1)}h',
                      background: isDark
                          ? const Color(0xFF2B2F36)
                          : const Color(0xFFF3F4F6),
                      textColor: titleColor,
                      subColor: bodyColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SimpleStatCard(
            color: cardColor,
            borderColor: borderColor,
            valueText: '${device.timeInGoodOrModeratePercentToday}%',
            valueColor: device.aqiLabel == 'Moderate'
                ? const Color(0xFFF59E0B)
                : const Color(0xFF3AB54A),
            caption: device.aqiLabel == 'Moderate'
                ? 'Time in Moderate AQI today'
                : 'Time in Good AQI today',
            captionStyle: bodyMedium.copyWith(
              color: bodyColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SimpleStatCard(
            color: cardColor,
            borderColor: borderColor,
            valueText: device.directHoursToday.toStringAsFixed(1),
            valueColor: const Color(0xFF3B82F6),
            caption: 'Direct Hours',
            captionStyle: bodyMedium.copyWith(
              color: bodyColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SimpleStatCard(
            color: cardColor,
            borderColor: borderColor,
            valueText: '${device.energySavedPercent}%',
            valueColor: const Color(0xFF8B5CF6),
            caption: 'Energy saved (Smart Mode)',
            captionStyle: bodyMedium.copyWith(
              color: bodyColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
