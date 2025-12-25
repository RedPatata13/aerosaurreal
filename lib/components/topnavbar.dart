import 'package:flutter/material.dart';
import '../platform/system_settings.dart';
import '../enum/active_icon.dart';

class TopNavbar extends StatelessWidget {
  final Color iconColor;
  final VoidCallback onBack;
  final bool activeAdd;

  final VoidCallback? onAdd;
  final VoidCallback? onNotifications;
  final VoidCallback? onSettings;
  final VoidCallback? onWifi;
  final TopNavActiveIcon activeIcon;

  const TopNavbar({
    super.key,
    required this.iconColor,
    required this.onBack,
    required this.activeAdd,
    this.onWifi,
    this.onAdd,
    this.onNotifications,
    this.onSettings,
    this.activeIcon = TopNavActiveIcon.none,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: Icon(Icons.arrow_back, color: iconColor),
          iconSize: 22,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        ),
        const Spacer(),

        // Wi-Fi icon
        _TopIconButton(
          onPressed: activeIcon == TopNavActiveIcon.wifi ? null : onWifi,
          icon: Icons.wifi,
          tooltip: 'Wi‑Fi',
          color: iconColor,
          active: activeIcon == TopNavActiveIcon.wifi,
        ),

        // Add icon
        _TopIconButton(
          onPressed: activeIcon == TopNavActiveIcon.add ? null : onAdd,
          icon: Icons.add,
          tooltip: 'Add device',
          color: iconColor,
          active: activeIcon == TopNavActiveIcon.add || activeAdd,
        ),

        // Notifications
        _TopIconButton(
          onPressed: activeIcon == TopNavActiveIcon.notifications
              ? null
              : onNotifications,
          icon: Icons.notifications_none,
          tooltip: 'Notifications',
          color: iconColor,
          active: activeIcon == TopNavActiveIcon.notifications,
        ),

        // Settings
        _TopIconButton(
          onPressed: activeIcon == TopNavActiveIcon.settings
              ? null
              : onSettings,
          icon: Icons.settings_outlined,
          tooltip: 'Settings',
          color: iconColor,
          active: activeIcon == TopNavActiveIcon.settings,
        ),
      ],
    );
  }
}

/// Private helper (file-scoped, correct)
class _TopIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;
  final Color color;
  final bool active;

  const _TopIconButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    required this.color,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = active ? null : onPressed;
    final effectiveColor = active ? color.withValues(alpha: 0.45) : color;

    return IconButton(
      onPressed: effectiveOnPressed,
      tooltip: tooltip,
      iconSize: 20,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      icon: Icon(icon, color: effectiveColor),
    );
  }
}
