import 'package:flutter/material.dart';

class RangeLabel extends StatelessWidget {
  final String label;
  final String range;

  const RangeLabel({super.key, required this.label, required this.range});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor =
        theme.textTheme.bodySmall?.color?.withOpacity(0.7) ??
        theme.colorScheme.onSurface.withOpacity(0.7);

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          range,
          style: TextStyle(
            color: textColor,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
