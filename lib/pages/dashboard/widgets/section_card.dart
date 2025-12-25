import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final Color cardColor;
  final Color borderColor;
  final TextStyle? titleStyle;

  const SectionCard({
    this.title,
    required this.child,
    required this.cardColor,
    required this.borderColor,
    this.titleStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null && title!.isNotEmpty) ...[
            Text(title!, style: titleStyle),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}
