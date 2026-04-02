import 'package:flutter/material.dart';

class DeviceRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final VoidCallback? onTrailingPressed;
  final Color borderColor;
  final Color titleColor;
  final Color subtitleColor;
  final IconData trailingIcon;
  final Color? trailingColor;

  const DeviceRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.borderColor,
    required this.titleColor,
    required this.subtitleColor,
    this.onTap,
    this.onTrailingPressed,
    this.trailingIcon = Icons.more_vert,
    this.trailingColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
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
                onPressed: onTrailingPressed ?? onTap,
                icon: Icon(
                  trailingIcon,
                  color: trailingColor ?? titleColor,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints.tightFor(
                  width: 36,
                  height: 36,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
