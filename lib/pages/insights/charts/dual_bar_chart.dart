import 'package:flutter/material.dart';
import 'bar.dart';

class DualBarChart extends StatelessWidget {
  final List<int> peak;
  final List<int> avg;
  final int maxValue;
  final double height;
  final Color peakColor;
  final Color avgColor;

  const DualBarChart({
    super.key,
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

    final gridColor = isDark
        ? const Color(0xFF2B2F36)
        : const Color(0xFFE5E7EB);
    final textColor = isDark
        ? const Color(0xFFB9C0CB)
        : const Color(0xFF6B7280);

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
                  .toList(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(
                      ticks.length,
                      (_) => Container(height: 1, color: gridColor),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(days.length, (index) {
                      final p = index < peak.length ? peak[index] : 0;
                      final a = index < avg.length ? avg[index] : 0;

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
                                    Bar(height: pH, width: 8, color: peakColor),
                                    const SizedBox(width: 4),
                                    Bar(height: aH, width: 8, color: avgColor),
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
