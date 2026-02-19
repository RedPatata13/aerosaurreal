import 'package:flutter/material.dart';

class GasCard extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final Color titleColor;
  final Color bodyColor;
  final bool harmfulGasDetected;

  const GasCard({
    super.key,
    required this.color,
    required this.borderColor,
    required this.titleColor,
    required this.bodyColor,
    required this.harmfulGasDetected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detected = harmfulGasDetected;
    final badgeBg =
        (detected ? const Color(0xFFEF5350) : const Color(0xFF3AB54A))
            .withValues(alpha: 0.18);
    final badgeTextColor = detected
        ? const Color(0xFFEF5350)
        : const Color(0xFF3AB54A);
    final badgeText = detected ? 'Detected' : 'Not Detected';
    final desc = detected
        ? 'Harmful gases detected. Improve ventilation.'
        : 'Air is safe from harmful gases.';

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
              color: badgeBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badgeText,
              style: TextStyle(
                color: badgeTextColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            style: theme.textTheme.bodySmall?.copyWith(color: bodyColor),
          ),
        ],
      ),
    );
  }
}
