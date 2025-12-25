import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TopIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;
  final Color color;
  final bool active;

  const TopIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.color = const Color(0xFF111827),
    this.active = false,
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
      icon: Icon(icon, color: effectiveColor),
    );
  }
}
