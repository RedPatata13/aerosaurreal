import 'package:flutter/material.dart';
import '/../components/topnavbar.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_tile.dart';
import '/../enum/active_icon.dart';
import '/services/wifi_service.dart';
import 'package:app_settings/app_settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../main.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              TopNavbar(
                iconColor: theme.colorScheme.onSurface,
                onBack: () => Navigator.pop(context),
                activeAdd: false,
                activeIcon: TopNavActiveIcon.settings,
              ),

              const SizedBox(height: 10),

              Expanded(
                child: ListView(
                  children: [
                    /// ACCOUNT MANAGEMENT
                    SettingsSection(
                      title: 'Account Management',
                      children: [
                        Builder(
                          builder: (context) {
                            final user = FirebaseAuth.instance.currentUser;
                            final hasGoogleProvider =
                                user?.providerData.any(
                                  (p) => p.providerId == 'google.com',
                                ) ??
                                false;

                            if (hasGoogleProvider) {
                              return Column(
                                children: [
                                  SettingsTile(
                                    icon: const Icon(Icons.email_outlined),
                                    title: 'Email',
                                    subtitle: user?.email ?? 'N/A',
                                  ),
                                  SettingsTile(
                                    icon: const Icon(Icons.person_outline),
                                    title: 'Username',
                                    subtitle: 'Set your username',
                                  ),
                                  SettingsTile(
                                    icon: const Icon(Icons.lock_outline),
                                    title: 'Set Password',
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () {},
                                  ),
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  SettingsTile(
                                    icon: const Icon(Icons.email_outlined),
                                    title: 'Email',
                                    subtitle: user?.email ?? 'N/A',
                                  ),
                                  SettingsTile(
                                    icon: const Icon(Icons.person_outline),
                                    title: 'Username',
                                    subtitle: user?.displayName ?? 'N/A',
                                  ),
                                  SettingsTile(
                                    icon: const Icon(Icons.lock_outline),
                                    title: 'Update Password',
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () {},
                                  ),
                                ],
                              );
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// CONNECTIVITY
                    SettingsSection(
                      title: 'Connectivity',
                      children: [
                        FutureBuilder<String?>(
                          future: WifiService.getWifiName(),
                          builder: (context, snapshot) {
                            final wifiName = snapshot.data;
                            final isConnected =
                                wifiName != null && wifiName.isNotEmpty;

                            return SettingsTile(
                              icon: const Icon(Icons.wifi),
                              title: 'Wi-Fi',
                              subtitle: isConnected
                                  ? wifiName
                                  : 'Not connected',
                              trailing: Text(
                                isConnected ? 'Connected' : 'Disconnected',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: isConnected
                                          ? Colors.green
                                          : Colors.grey,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              onTap: () {
                                AppSettings.openAppSettings(
                                  type: AppSettingsType.wifi,
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// APPEARANCE
                    SettingsSection(
                      title: 'Appearance',
                      children: [
                        SwitchListTile(
                          secondary: Icon(
                            Icons.dark_mode,
                            color: Theme.of(context).iconTheme.color,
                          ),
                          title: const Text('Dark Mode'),
                          value:
                              Theme.of(context).brightness == Brightness.dark,
                          onChanged: (value) {
                            MyApp.of(context).setThemeMode(
                              value ? ThemeMode.dark : ThemeMode.light,
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// BOUND ACCOUNTS
                    SettingsSection(
                      title: 'Bound Accounts',
                      children: [
                        Builder(
                          builder: (context) {
                            final theme = Theme.of(context);
                            final user = FirebaseAuth.instance.currentUser;

                            final hasGoogleProvider =
                                user?.providerData.any(
                                  (p) => p.providerId == 'google.com',
                                ) ??
                                false;

                            final googleProvider = hasGoogleProvider
                                ? user!.providerData.firstWhere(
                                    (p) => p.providerId == 'google.com',
                                  )
                                : null;

                            return SettingsTile(
                              icon: Image.asset(
                                'images/google_logo.png',
                                height: 24,
                              ),
                              title: 'Google',
                              subtitle: hasGoogleProvider
                                  ? googleProvider!.email
                                  : 'No account connected',
                              trailing: Chip(
                                label: Text(
                                  hasGoogleProvider
                                      ? 'Connected'
                                      : 'Not connected',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                backgroundColor: theme.colorScheme.primary,
                                side: BorderSide.none,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    /// LOGOUT
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFA31618),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Confirm Logout'),
                            content: const Text(
                              'Are you sure you want to logout?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text('Logout'),
                              ),
                            ],
                          ),
                        );

                        if (shouldLogout ?? false) {
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
