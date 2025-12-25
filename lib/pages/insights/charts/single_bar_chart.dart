import 'package:flutter/material.dart';
import 'bar.dart';

class SingleBarChart extends StatelessWidget {
  final List<double> values;
  final double maxValue;
  final double height;
  final Color barColor;

  const SingleBarChart({
    super.key,
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

    final gridColor = isDark
        ? const Color(0xFF2B2F36)
        : const Color(0xFFE5E7EB);
    final textColor = isDark
        ? const Color(0xFFB9C0CB)
        : const Color(0xFF6B7280);

    return SizedBox(
      height: height + 40,
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(days.length, (index) {
              final v = index < values.length ? values[index] : 0.0;
              final h = (v / maxValue).clamp(0.0, 1.0) * height;

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      v.toStringAsFixed(1),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Bar(height: h, width: 18, color: barColor),
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
