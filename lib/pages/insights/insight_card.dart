import 'package:flutter/material.dart';

class InsightCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color color;
  final Color borderColor;
  final TextStyle titleStyle;

  const InsightCard({
    super.key,
    required this.title,
    required this.child,
    required this.color,
    required this.borderColor,
    required this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(title, style: titleStyle),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
