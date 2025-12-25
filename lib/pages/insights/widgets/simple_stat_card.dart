import 'package:flutter/material.dart';

class SimpleStatCard extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final String valueText;
  final Color valueColor;
  final String caption;
  final TextStyle captionStyle;

  const SimpleStatCard({
    super.key,
    required this.color,
    required this.borderColor,
    required this.valueText,
    required this.valueColor,
    required this.caption,
    required this.captionStyle,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
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
      ),
    );
  }
}
