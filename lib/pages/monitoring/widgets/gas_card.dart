import 'package:flutter/material.dart';

class GasCard extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final Color titleColor;
  final Color bodyColor;

  const GasCard({
    super.key,
    required this.color,
    required this.borderColor,
    required this.titleColor,
    required this.bodyColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 16, color: titleColor),
              const SizedBox(width: 6),
              Text(
                'Harmful Gases',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF3AB54A).withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Not Detected',
              style: TextStyle(
                color: Color(0xFF3AB54A),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Air is safe from harmful gases.',
            style: theme.textTheme.bodySmall?.copyWith(color: bodyColor),
          ),
        ],
      ),
    );
  }
}
