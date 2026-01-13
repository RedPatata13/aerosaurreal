import 'package:flutter/material.dart';
import '/../../models/device.dart';
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

    final titleStyle =
        theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: (theme.textTheme.titleMedium?.fontSize ?? 16) + 1,
          color: theme.colorScheme.onSurface,
        ) ??
        TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 17,
          color: theme.colorScheme.onSurface,
        );

    final bodyStyle =
        theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ) ??
        TextStyle(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        );

    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final borderColor = theme.dividerColor;

    const graphPrimary = Color(0xFF415A77);
    const graphSecondary = Color(0xFFA8AFBA);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      child: Column(
        children: [
          InsightCard(
            title: 'Air Quality Index Trend',
            color: cardColor,
            borderColor: borderColor,
            titleStyle: titleStyle,
            child: Column(
              children: [
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const LegendDot(color: graphSecondary),
                    const SizedBox(width: 6),
                    Text('Peak AQI', style: bodyStyle),
                    const SizedBox(width: 16),
                    const LegendDot(color: graphPrimary),
                    const SizedBox(width: 6),
                    Text('Average AQI', style: bodyStyle),
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
            titleStyle: titleStyle,
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
                      background: cardColor,
                      textColor: theme.colorScheme.onSurface,
                      subColor: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                    const SizedBox(width: 10),
                    StatPill(
                      label: 'Daily Usage',
                      value: '${device.dailyUsageHours.toStringAsFixed(1)}h',
                      background: cardColor,
                      textColor: theme.colorScheme.onSurface,
                      subColor: theme.colorScheme.onSurface.withOpacity(0.7),
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
            captionStyle: bodyStyle,
          ),
          const SizedBox(height: 10),
          SimpleStatCard(
            color: cardColor,
            borderColor: borderColor,
            valueText: device.directHoursToday.toStringAsFixed(1),
            valueColor: const Color(0xFF3B82F6),
            caption: 'Direct Hours',
            captionStyle: bodyStyle,
          ),
          const SizedBox(height: 10),
          SimpleStatCard(
            color: cardColor,
            borderColor: borderColor,
            valueText: '${device.energySavedPercent}%',
            valueColor: const Color(0xFF8B5CF6),
            caption: 'Energy saved (Smart Mode)',
            captionStyle: bodyStyle,
          ),
        ],
      ),
    );
  }
}
