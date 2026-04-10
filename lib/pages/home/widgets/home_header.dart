import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../../components/tutorial_showcase.dart';
import '../../../platform/system_settings.dart';
import '../../../state/notifications_store.dart';
import 'top_icon_button.dart';
import '../../../routes/routes.dart';

class HomeHeader extends StatelessWidget {
  final String username;
  final Color iconColor;
  final VoidCallback onRegisterDevice;
  final VoidCallback? onShowTutorial;
  final GlobalKey? tutorialButtonKey;
  final GlobalKey? addButtonKey;
  final GlobalKey? notificationsButtonKey;
  final GlobalKey? settingsButtonKey;

  const HomeHeader({
    super.key,
    required this.username,
    required this.iconColor,
    required this.onRegisterDevice,
    this.onShowTutorial,
    this.tutorialButtonKey,
    this.addButtonKey,
    this.notificationsButtonKey,
    this.settingsButtonKey,
  });

  Widget _wrapShowcase({
    required Widget child,
    required GlobalKey? showcaseKey,
    required String title,
    required String description,
    ShapeBorder? shapeBorder,
    TooltipPosition? tooltipPosition,
  }) {
    return wrapTutorialShowcase(
      child: child,
      showcaseKey: showcaseKey,
      title: title,
      description: description,
      shapeBorder: shapeBorder,
      tooltipPosition: tooltipPosition,
    );
  }

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
              backgroundColor: theme.primaryColor.withValues(alpha: 0.75),
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
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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

          if (onShowTutorial != null) ...[
            _wrapShowcase(
              showcaseKey: tutorialButtonKey,
              title: 'Need a quick tour?',
              description:
                  'Tap this help button anytime to replay the walkthrough and learn what each part of the app does.',
              shapeBorder: const CircleBorder(),
              tooltipPosition: TooltipPosition.bottom,
              child: TopIconButton(
                onPressed: onShowTutorial!,
                icon: Icons.help_outline_rounded,
                tooltip: 'Show tutorial',
                color: iconColor,
              ),
            ),
            const SizedBox(width: 4),
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

          _wrapShowcase(
            showcaseKey: addButtonKey,
            title: 'Register a device',
            description:
                'Use this button to add a purifier to your account or open device management after setup.',
            shapeBorder: const CircleBorder(),
            tooltipPosition: TooltipPosition.bottom,
            child: TopIconButton(
              onPressed: onRegisterDevice,
              icon: Icons.add,
              tooltip: 'Register device',
              color: iconColor,
            ),
          ),
          const SizedBox(width: 4),

          _wrapShowcase(
            showcaseKey: notificationsButtonKey,
            title: 'Notifications',
            description:
                'Open alerts, system messages, and device updates. A red dot appears here when something new arrives.',
            shapeBorder: const CircleBorder(),
            tooltipPosition: TooltipPosition.bottom,
            child: TopIconButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.notifications);
              },
              icon: Icons.notifications_none,
              tooltip: 'Notifications',
              color: iconColor,
              showIndicator: context.select<NotificationsStore, bool>(
                (store) => store.hasUnread,
              ),
            ),
          ),
          const SizedBox(width: 4),

          _wrapShowcase(
            showcaseKey: settingsButtonKey,
            title: 'Settings',
            description:
                'Manage your account, password, connected services, app appearance, and subscription details here.',
            shapeBorder: const CircleBorder(),
            tooltipPosition: TooltipPosition.bottom,
            child: TopIconButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.settings);
              },
              icon: Icons.settings_outlined,
              tooltip: 'Settings',
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }
}
