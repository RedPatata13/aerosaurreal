import 'package:flutter/material.dart';

import '../components/aqi_card.dart';
import '../components/info_dialog.dart';
import '../models/device.dart';

class Insights extends StatelessWidget {
  final Device device;

  const Insights({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827);
    final bodyColor = isDark ? const Color(0xFFB9C0CB) : const Color(0xFF4B5563);
    final primary = isDark ? const Color(0xFF415A77) : const Color(0xFF1B263B);
    final cardColor = isDark ? const Color(0xFF1F2228) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2B2F36) : const Color(0xFFE5E7EB);
    const graphPrimary = Color(0xFF415A77);
    const graphSecondary = Color(0xFFA8AFBA);

    final titleMedium =
        theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);
    final bodyMedium = theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
    final sectionTitleStyle = titleMedium.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: (titleMedium.fontSize ?? 16) + 1,
      color: titleColor,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InsightCard(
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
                    _LegendDot(
                      color: graphSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Peak AQI',
                      style: bodyMedium.copyWith(
                        color: bodyColor,
                        fontSize: (bodyMedium.fontSize ?? 14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 16),
                    _LegendDot(
                      color: graphPrimary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Average AQI',
                      style: bodyMedium.copyWith(
                        color: bodyColor,
                        fontSize: (bodyMedium.fontSize ?? 14),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _DualBarChart(
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
                    Expanded(child: _RangeLabel(label: 'Good', range: '(0-50)')),
                    Expanded(
                      child: _RangeLabel(label: 'Moderate', range: '(51-100)'),
                    ),
                    Expanded(
                      child:
                          _RangeLabel(label: 'Unhealthy', range: '(101 - 150)'),
                    ),
                    Expanded(
                      child: _RangeLabel(label: 'Dangerous', range: '(150+)'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _InsightCard(
            title: 'Purifier Usage - Over 7 Days',
            color: cardColor,
            borderColor: borderColor,
            titleStyle: sectionTitleStyle,
            child: Column(
              children: [
                const SizedBox(height: 10),
                _SingleBarChart(
                  values: device.purifierUsageHours7d,
                  maxValue: 16.5,
                  height: 160,
                  barColor: graphPrimary,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatPill(
                      label: 'Total Usage',
                      value: '${device.totalUsageHours7d.toStringAsFixed(1)}h',
                      background: isDark
                          ? const Color(0xFF2B2F36)
                          : const Color(0xFFF3F4F6),
                      textColor: titleColor,
                      subColor: bodyColor,
                    ),
                    const SizedBox(width: 10),
                    _StatPill(
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
          _SimpleStatCard(
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
              fontSize: (bodyMedium.fontSize ?? 14),
            ),
          ),
          const SizedBox(height: 10),
          _SimpleStatCard(
            color: cardColor,
            borderColor: borderColor,
            valueText: device.directHoursToday.toStringAsFixed(1),
            valueColor: const Color(0xFF3B82F6),
            caption: 'Direct Hours',
            captionStyle: bodyMedium.copyWith(
              color: bodyColor,
              fontWeight: FontWeight.w600,
              fontSize: (bodyMedium.fontSize ?? 14),
            ),
          ),
          const SizedBox(height: 10),
          _SimpleStatCard(
            color: cardColor,
            borderColor: borderColor,
            valueText: '${device.energySavedPercent}%',
            valueColor: const Color(0xFF8B5CF6),
            caption: 'Energy saved (Smart Mode)',
            captionStyle: bodyMedium.copyWith(
              color: bodyColor,
              fontWeight: FontWeight.w600,
              fontSize: (bodyMedium.fontSize ?? 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color color;
  final Color borderColor;
  final TextStyle titleStyle;

  const _InsightCard({
    required this.title,
    required this.child,
    required this.color,
    required this.borderColor,
    required this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: titleStyle),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;

  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _RangeLabel extends StatelessWidget {
  final String label;
  final String range;

  const _RangeLabel({required this.label, required this.range});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? const Color(0xFFB9C0CB) : const Color(0xFF4B5563);
    return SizedBox(
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            range,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DualBarChart extends StatelessWidget {
  final List<int> peak;
  final List<int> avg;
  final int maxValue;
  final double height;
  final Color peakColor;
  final Color avgColor;

  const _DualBarChart({
    required this.peak,
    required this.avg,
    required this.maxValue,
    required this.height,
    required this.peakColor,
    required this.avgColor,
  });

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gridColor =
        isDark ? const Color(0xFF2B2F36) : const Color(0xFFE5E7EB);
    final textColor =
        isDark ? const Color(0xFFB9C0CB) : const Color(0xFF6B7280);

    const ticks = [150, 100, 50, 0];

    return SizedBox(
      height: height + 26,
      child: Row(
        children: [
          SizedBox(
            width: 28,
            height: height,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: ticks
                  .map(
                    (t) => Text(
                      '$t',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (int i = 0; i < ticks.length; i++)
                        Container(
                          height: 1,
                          color: gridColor,
                        ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(days.length, (index) {
                      final p = (index < peak.length) ? peak[index] : 0;
                      final a = (index < avg.length) ? avg[index] : 0;
                      final pH = (p / maxValue).clamp(0.0, 1.0) * height;
                      final aH = (a / maxValue).clamp(0.0, 1.0) * height;
                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: height,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _Bar(height: pH, color: peakColor, width: 8),
                                    const SizedBox(width: 4),
                                    _Bar(height: aH, color: avgColor, width: 8),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              days[index],
                              style: TextStyle(
                                color: textColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SingleBarChart extends StatelessWidget {
  final List<double> values;
  final double maxValue;
  final double height;
  final Color barColor;

  const _SingleBarChart({
    required this.values,
    required this.maxValue,
    required this.height,
    required this.barColor,
  });

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final gridColor =
        isDark ? const Color(0xFF2B2F36) : const Color(0xFFE5E7EB);
    final textColor =
        isDark ? const Color(0xFFB9C0CB) : const Color(0xFF6B7280);

    const valueLabelHeight = 16.0;
    const valueToBarGap = 4.0;
    const topPad = valueLabelHeight + valueToBarGap;
    final barMaxHeight = (height - topPad).clamp(0.0, height);

    return SizedBox(
      height: height + 40,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(days.length, (index) {
              final v = (index < values.length) ? values[index] : 0.0;
              final h = (v / maxValue).clamp(0.0, 1.0) * barMaxHeight;
              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SizedBox(
                      height: height,
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            height: valueLabelHeight,
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  v.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Positioned.fill(
                            top: topPad,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: _Bar(height: h, color: barColor, width: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      days[index],
                      style: TextStyle(
                        color: textColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Container(height: 1, color: gridColor),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final double width;
  final Color color;

  const _Bar({required this.height, required this.color, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color background;
  final Color textColor;
  final Color subColor;

  const _StatPill({
    required this.label,
    required this.value,
    required this.background,
    required this.textColor,
    required this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: subColor,
              fontWeight: FontWeight.w700,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _SimpleStatCard extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final String valueText;
  final Color valueColor;
  final String caption;
  final TextStyle captionStyle;

  const _SimpleStatCard({
    required this.color,
    required this.borderColor,
    required this.valueText,
    required this.valueColor,
    required this.caption,
    required this.captionStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        children: [
          Text(
            valueText,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w800,
              fontSize: 22,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(caption, style: captionStyle),
        ],
      ),
    );
  }
}
