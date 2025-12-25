import 'package:flutter/material.dart';

class DeviceRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onDelete;
  final Color danger;
  final Color borderColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color cardBg;

  const DeviceRow({
    required this.title,
    required this.subtitle,
    required this.onDelete,
    required this.danger,
    required this.borderColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: subtitleColor,
                    fontWeight: FontWeight.w600,
                    fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12) - 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete, color: danger, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            ),
          ),
        ],
      ),
    );
  }
}
