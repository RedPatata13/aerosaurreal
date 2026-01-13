import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_settings/app_settings.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_tile.dart';
import '../../main.dart';
import './../home/widgets/home_header.dart';
import './../device_management/device_management.dart';
import 'dialogs/change_email_dialog/update_email_dialog.dart';
import 'dialogs/change_username_dialog/update_username_dialog.dart';
import '/services/wifi_service.dart';
import '../../../models/device.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<Device> devicesState = [];
  int selectedDeviceIndex = 0;

  void _showRegisterDeviceDialog(String uid) {
    showDialog(
      context: context,
      builder: (_) => DeviceManagementPage(
        uid: uid,
        devices: devicesState,
        onDevicesChanged: (next) {
          setState(() {
            devicesState = next;
            if (selectedDeviceIndex >= next.length) selectedDeviceIndex = 0;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.displayName ?? 'User';
    final uid = user?.uid;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            /// HomeHeader
            HomeHeader(
              username: username,
              iconColor: theme.colorScheme.onSurface,
              onRegisterDevice: () {
                if (uid == null) return;
                _showRegisterDeviceDialog(uid);
              },
            ),
            const SizedBox(height: 10),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                children: [
                  /// Account Management
                  SettingsSection(
                    title: 'Account Management',
                    children: [
                      Builder(
                        builder: (context) {
                          final hasGoogleProvider =
                              user?.providerData.any(
                                (p) => p.providerId == 'google.com',
                              ) ??
                              false;
                          final hasPassword =
                              user?.providerData.any(
                                (p) => p.providerId == 'password',
                              ) ??
                              false;
                          final email = user?.email;

                          return Column(
                            children: [
                              SettingsTile(
                                icon: const Icon(Icons.email_outlined),
                                title: 'Email',
                                subtitle:
                                    user?.email ??
                                    (hasGoogleProvider ? 'N/A' : 'Not set'),
                                trailing: hasGoogleProvider
                                    ? const Icon(Icons.chevron_right)
                                    : null,
                                onTap: hasGoogleProvider
                                    ? () async {
                                        await showDialog<bool>(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (_) =>
                                              const UpdateEmailDialog(),
                                        );
                                      }
                                    : null,
                              ),
                              SettingsTile(
                                icon: const Icon(Icons.person_outline),
                                title: 'Username',
                                subtitle:
                                    user?.displayName ??
                                    (hasGoogleProvider
                                        ? 'Set your username'
                                        : 'N/A'),
                                trailing: hasGoogleProvider
                                    ? const Icon(Icons.chevron_right)
                                    : null,
                                onTap: hasGoogleProvider
                                    ? () async {
                                        await showDialog<bool>(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (_) =>
                                              const UpdateUsernameDialog(),
                                        );
                                      }
                                    : null,
                              ),
                              SettingsTile(
                                icon: const Icon(Icons.lock_outline),
                                title: hasPassword
                                    ? 'Update Password'
                                    : 'Set Password',
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () async {
                                  if (email == null || email.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Set up your email first to manage password',
                                        ),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                    return;
                                  }

                                  try {
                                    await FirebaseAuth.instance
                                        .sendPasswordResetEmail(email: email);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Password reset email sent',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to send reset email: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  /// Connectivity
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
                            subtitle: isConnected ? wifiName : 'Not connected',
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

                  /// Appearance
                  SettingsSection(
                    title: 'Appearance',
                    children: [
                      SwitchListTile(
                        secondary: Icon(
                          Icons.dark_mode,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        title: const Text('Dark Mode'),
                        value: Theme.of(context).brightness == Brightness.dark,
                        onChanged: (value) {
                          MyApp.of(context).setThemeMode(
                            value ? ThemeMode.dark : ThemeMode.light,
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  /// Bound Accounts
                  SettingsSection(
                    title: 'Bound Accounts',
                    children: [
                      Builder(
                        builder: (context) {
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

                  /// Logout
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
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
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
    );
  }
}
