import 'package:flutter/material.dart';
import 'legend_item.dart';

class MonitoringLegend extends StatelessWidget {
  const MonitoringLegend({super.key});

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
                LegendItem(label: 'Safe', color: Color(0xFF3AB54A)),
                SizedBox(width: 26),
                LegendItem(label: 'Moderate', color: Color(0xFFFF9800)),
              ],
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                LegendItem(label: 'Unhealthy', color: Color(0xFFFFC107)),
                SizedBox(width: 26),
                LegendItem(label: 'Dangerous', color: Color(0xFFE53935)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
