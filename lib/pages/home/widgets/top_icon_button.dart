import 'package:flutter/material.dart';

class TopIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;
  final Color color;
  final bool active;
  final bool showIndicator;

  const TopIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.color = const Color(0xFF111827),
    this.active = false,
    this.showIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = active
        ? color.withValues(alpha: 0.45)
        : color.withValues(alpha: 1);

    return IconButton(
      onPressed: active ? null : onPressed,
      tooltip: tooltip,
      iconSize: 20,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon, color: effectiveColor),
          if (showIndicator)
            Positioned(
              top: -1,
              right: -1,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 1.2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
