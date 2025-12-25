import 'package:flutter/material.dart';
import '../../settings.dart';
import '../../../platform/system_settings.dart';
import 'top_icon_button.dart';

class HomeHeader extends StatelessWidget {
  final String username;
  final Color iconColor;
  final VoidCallback onRegisterDevice;

  const HomeHeader({
    super.key,
    required this.username,
    required this.iconColor,
    required this.onRegisterDevice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const navy = Color(0xFF1B263B);
    const slate = Color(0xFF415A77);
    final titleColor = isDark
        ? const Color(0xFFF3F4F6)
        : const Color(0xFF111827);
    final bodySmall =
        theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    final titleMedium =
        theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isDark
                ? slate.withValues(alpha: 0.75)
                : const Color(0xFFF2F4F7),
            child: Icon(
              Icons.person_outline,
              color: isDark ? Colors.white : navy,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello!',
                  style: bodySmall.copyWith(
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                ),
                Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: (titleMedium.fontSize ?? 16) + 2,
                    color: titleColor,
                  ),
                ),
              ],
            ),
          ),
          TopIconButton(
            onPressed: () async {
              try {
                await SystemSettings.openWifiSettings();
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Unable to open Wi-Fi settings.'),
                  ),
                );
              }
            },
            icon: Icons.wifi,
            tooltip: 'Wi-Fi',
            color: iconColor,
          ),
          const SizedBox(width: 4),
          TopIconButton(
            onPressed: onRegisterDevice,
            icon: Icons.add,
            tooltip: 'Register device',
            color: iconColor,
          ),
          const SizedBox(width: 4),
          TopIconButton(
            onPressed: () {},
            icon: Icons.notifications_none,
            tooltip: 'Notifications',
            color: iconColor,
          ),
          const SizedBox(width: 4),
          TopIconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            icon: Icons.settings_outlined,
            tooltip: 'Settings',
            color: iconColor,
          ),
        ],
      ),
    );
  }
}
