import 'package:flutter/material.dart';
import '../../../platform/system_settings.dart';
import 'top_icon_button.dart';
import '../../../routes/routes.dart';

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

    final routeName = ModalRoute.of(context)?.settings.name;
    final isHome = routeName == AppRoutes.home;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 10),
      child: Row(
        children: [
          if (isHome) ...[
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.primaryColor.withOpacity(0.75),
              child: Icon(
                Icons.person_outline,
                color: theme.colorScheme.onPrimary,
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
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    username,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize:
                          (theme.textTheme.titleMedium?.fontSize ?? 16) + 2,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            IconButton(
              padding: EdgeInsets.zero,
              iconSize: 20,
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 20,
                color: iconColor,
              ),
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false);
              },
            ),
            const Spacer(),
          ],

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
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.notifications);
            },
            icon: Icons.notifications_none,
            tooltip: 'Notifications',
            color: iconColor,
          ),
          const SizedBox(width: 4),

          TopIconButton(
            onPressed: () {
              Navigator.of(context).pushNamed(AppRoutes.settings);
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
