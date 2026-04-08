import 'package:flutter/material.dart';
import '../../../components/tutorial_showcase.dart';

class NoDeviceContent extends StatelessWidget {
  final VoidCallback onRegisterDevice;
  final VoidCallback onLogout;
  final GlobalKey? registerButtonKey;

  const NoDeviceContent({
    super.key,
    required this.onRegisterDevice,
    required this.onLogout,
    this.registerButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final registerButton = SizedBox(
      height: 40,
      child: ElevatedButton.icon(
        onPressed: onRegisterDevice,
        icon: const Icon(Icons.link, size: 18),
        label: const Text('Register new device'),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          textStyle: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) - 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor, width: 1.2),
              boxShadow: theme.brightness == Brightness.dark
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x11000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 34, 18, 28),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'No devices registered on your account.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "It appears you don't have any devices registered. Register your device now!",
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 330),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: registerButtonKey == null
                        ? registerButton
                        : wrapTutorialShowcase(
                            child: registerButton,
                            showcaseKey: registerButtonKey,
                            title: 'Start by adding a device',
                            description:
                                'Register your purifier here so the app can show live air quality, controls, alerts, and analytics.',
                          ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 40,
                    width: 120,
                    child: ElevatedButton.icon(
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        textStyle: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize:
                              (theme.textTheme.bodyMedium?.fontSize ?? 14) - 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
