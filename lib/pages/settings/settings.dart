import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_settings/app_settings.dart';
import '../../components/app_dialogs.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_tile.dart';
import '../../main.dart';
import '../../routes/routes.dart';
import './../home/widgets/home_header.dart';
import '../../services/api/api_client.dart';
import '../../services/device/wifi_service.dart';
import '../device_management/device_management_args.dart';
import 'dialogs/change_email_dialog/update_email_dialog.dart';
import 'dialogs/change_password_dialog/set_password_dialog.dart';
import 'dialogs/change_username_dialog/update_username_dialog.dart';
import '../../services/auth/google_auth_service.dart';
import '../../services/repositories/premium_repository.dart';
import '../../models/device.dart';
import 'package:provider/provider.dart';
import '../../state/user_store.dart';
import '../../services/location/location_access_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final GoogleAuthService _googleAuthService = GoogleAuthService();
  List<Device> devicesState = [];
  int selectedDeviceIndex = 0;
  bool _linkingGoogle = false;
  Future<Map<String, dynamic>>? _premiumStatusFuture;
  Future<_ConnectivityState>? _connectivityFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    _premiumStatusFuture ??= _loadPremiumStatus(uid);
    _connectivityFuture ??= _loadConnectivityState();
  }

  Future<Map<String, dynamic>> _loadPremiumStatus(String uid) {
    return PremiumRepository(context.read<ApiClient>()).getPremiumStatus(uid);
  }

  Future<void> _openPremiumPage() async {
    await Navigator.of(context).pushNamed(AppRoutes.premium);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (!mounted || uid == null) return;

    setState(() {
      _premiumStatusFuture = _loadPremiumStatus(uid);
    });
  }

  Future<_ConnectivityState> _loadConnectivityState() async {
    final locationIssue = await LocationAccessService.getIssue();
    final wifiName = locationIssue == LocationAccessIssue.none
        ? await WifiService.getWifiName()
        : null;

    return _ConnectivityState(locationIssue: locationIssue, wifiName: wifiName);
  }

  Future<void> _refreshConnectivityState() async {
    if (!mounted) return;
    setState(() {
      _connectivityFuture = _loadConnectivityState();
    });
  }

  Future<void> _showLocationResolutionDialog(
    LocationAccessIssue issue,
  ) async {
    if (issue == LocationAccessIssue.none) {
      return;
    }

    if (issue == LocationAccessIssue.permissionDenied) {
      await showAppMessageDialog(
        context,
        title: 'Location Permission Needed',
        message:
            'Allow location permission so Aerosaur can detect your Wi-Fi and use device setup features properly.',
        actionLabel: 'OK',
      );
      return;
    }

    final shouldOpen = await showAppConfirmationDialog(
      context,
      title: issue == LocationAccessIssue.serviceDisabled
          ? 'Turn On Location'
          : 'Location Permission Needed',
      message: issue == LocationAccessIssue.serviceDisabled
          ? 'Your phone location is turned off. Enable it so Wi-Fi and connectivity features work properly.'
          : 'Location permission is disabled for this app. Open settings to enable it.',
      cancelLabel: 'Close',
      confirmLabel: issue == LocationAccessIssue.serviceDisabled
          ? 'Open Location'
          : 'Open Settings',
    );

    if (!shouldOpen) {
      return;
    }

    await LocationAccessService.openResolution(issue);
    await _refreshConnectivityState();
  }

  String _formatPlanName(String? planId) {
    if (planId == null || planId.isEmpty) return 'No active plan';

    switch (planId) {
      case 'PREMIUM_QUARTERLY':
        return 'Premium Quarterly';
      default:
        if (planId.startsWith('P-')) return 'Premium Plan';
        return planId.replaceAll('_', ' ');
    }
  }

  String _formatExpiry(String? raw) {
    if (raw == null || raw.isEmpty) return 'No renewal date yet';

    try {
      final date = DateTime.parse(raw).toLocal();
      const months = [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ];

      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return raw;
    }
  }

  Future<void> _linkGoogleAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _linkingGoogle) {
      return;
    }

    setState(() {
      _linkingGoogle = true;
    });

    try {
      await _googleAuthService.signOutGoogle();
      final credential = await _googleAuthService.getGoogleCredential();
      await user.linkWithCredential(credential);
      await user.reload();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google account connected successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {});
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      var message = 'Failed to connect Google account.';
      switch (e.code) {
        case 'provider-already-linked':
          message = 'This Google account is already linked.';
          break;
        case 'credential-already-in-use':
          message = 'That Google account is already used by another user.';
          break;
        case 'email-already-in-use':
          message = 'That Google email is already used by another account.';
          break;
        case 'requires-recent-login':
          message = 'Please log in again before connecting Google.';
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect Google account: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _linkingGoogle = false;
        });
      }
    }
  }

  Future<void> _openDeviceManagement(String uid) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.deviceManagement,
      arguments: DeviceManagementArgs(
        uid: uid,
        devices: devicesState,
        onDevicesChanged: (next) {
          if (!mounted) {
            return;
          }
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
    final uid = user?.uid;
    final userStore = context.watch<UserStore>();
    final shownUsername = userStore.username;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HomeHeader(
              username: shownUsername,
              iconColor: theme.colorScheme.onSurface,
              onRegisterDevice: () {
                if (uid == null) return;
                _openDeviceManagement(uid);
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
                          final hasPassword =
                              user?.providerData.any(
                                (p) => p.providerId == 'password',
                              ) ??
                              false;

                          final email = user?.email;
                          final isLoggedIn = user != null;

                          return Column(
                            children: [
                              SettingsTile(
                                icon: const Icon(Icons.email_outlined),
                                title: 'Email',
                                subtitle: user?.email ?? 'Not set',
                                trailing: isLoggedIn
                                    ? const Icon(Icons.chevron_right)
                                    : null,
                                onTap: isLoggedIn
                                    ? () async {
                                        await showDialog<bool>(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (_) =>
                                              UpdateEmailDialog(user: user),
                                        );
                                        if (!mounted) return;
                                        setState(() {});
                                      }
                                    : null,
                              ),
                              SettingsTile(
                                icon: const Icon(Icons.person_outline),
                                title: 'Username',
                                subtitle: shownUsername,
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () async {
                                  await showDialog<bool>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) =>
                                        const UpdateUsernameDialog(),
                                  );
                                },
                              ),
                              SettingsTile(
                                icon: const Icon(Icons.lock_outline),
                                title: hasPassword
                                    ? 'Update Password'
                                    : 'Set Password',
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () async {
                                  if (email == null || email.isEmpty) {
                                    await showAppMessageDialog(
                                      context,
                                      title: 'Email Required',
                                      message:
                                          'Set up your email first to manage password.',
                                    );
                                    return;
                                  }

                                  if (!hasPassword) {
                                    final result = await showDialog<bool>(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) =>
                                          SetPasswordDialog(user: user!),
                                    );

                                    if (!mounted) return;

                                    if (result == true) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Password added to this account successfully.',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      setState(() {});
                                    }
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

                  /// Subscription
                  SettingsSection(
                    title: 'Subscription',
                    children: [
                      FutureBuilder<Map<String, dynamic>>(
                        future: _premiumStatusFuture,
                        builder: (context, snapshot) {
                          final data = snapshot.data;
                          final isPremium = data?['isPremium'] == true;
                          final status = (data?['status'] ?? '')
                              .toString()
                              .toUpperCase();
                          final isCancelledButActive =
                              isPremium && status == 'CANCELLED';
                          final shouldShowExpiry = isPremium;
                          final planName = _formatPlanName(
                            data?['premiumPlan']?.toString(),
                          );
                          final expiryLabel = shouldShowExpiry
                              ? _formatExpiry(data?['expiresAt']?.toString())
                              : 'No active premium plan';
                          final statusText =
                              snapshot.connectionState ==
                                  ConnectionState.waiting
                              ? 'Checking...'
                              : isCancelledButActive
                              ? 'Cancelled'
                              : isPremium
                              ? 'Subscribed'
                              : 'Free';
                          final statusColor =
                              snapshot.connectionState ==
                                  ConnectionState.waiting
                              ? Colors.grey
                              : isCancelledButActive
                              ? Colors.orange
                              : isPremium
                              ? Colors.green
                              : theme.colorScheme.primary;

                          return Column(
                            children: [
                              SettingsTile(
                                icon: const Icon(
                                  Icons.workspace_premium_outlined,
                                ),
                                title: 'Plan',
                                subtitle:
                                    snapshot.connectionState ==
                                        ConnectionState.waiting
                                    ? 'Checking your subscription...'
                                    : isPremium
                                    ? planName
                                    : 'Free Plan',
                                trailing: Chip(
                                  label: Text(
                                    statusText,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  backgroundColor: statusColor,
                                  side: BorderSide.none,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              SettingsTile(
                                icon: const Icon(Icons.event_outlined),
                                title: isPremium ? 'Renews On' : 'Subscription',
                                subtitle: expiryLabel,
                              ),
                              SettingsTile(
                                icon: const Icon(
                                  Icons.arrow_circle_up_outlined,
                                ),
                                title: isPremium
                                    ? 'Manage Subscription'
                                    : 'Upgrade to Premium',
                                subtitle: isPremium
                                    ? 'View your premium page and current access details.'
                                    : 'Unlock all access',
                                trailing: const Icon(Icons.chevron_right),
                                onTap: _openPremiumPage,
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
                      FutureBuilder<_ConnectivityState>(
                        future: _connectivityFuture,
                        builder: (context, snapshot) {
                          final connectivity =
                              snapshot.data ??
                              const _ConnectivityState(
                                locationIssue: LocationAccessIssue.permissionDenied,
                              );
                          final locationIssue = connectivity.locationIssue;
                          final locationReady =
                              locationIssue == LocationAccessIssue.none;
                          final wifiName = connectivity.wifiName;
                          final isConnected =
                              locationReady &&
                              wifiName != null &&
                              wifiName.isNotEmpty;

                          final locationSubtitle = switch (locationIssue) {
                            LocationAccessIssue.none =>
                              'Enabled and ready',
                            LocationAccessIssue.serviceDisabled =>
                              'Phone location is turned off',
                            LocationAccessIssue.permissionPermanentlyDenied =>
                              'Permission is disabled for this app',
                            LocationAccessIssue.permissionDenied =>
                              'Permission is required for Wi-Fi detection',
                          };

                          final locationStatusText = switch (locationIssue) {
                            LocationAccessIssue.none => 'On',
                            _ => 'Off',
                          };

                          return Column(
                            children: [
                              SettingsTile(
                                icon: const Icon(Icons.location_on_outlined),
                                title: 'Location',
                                subtitle: locationSubtitle,
                                trailing: Text(
                                  locationStatusText,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: locationReady
                                            ? Colors.green
                                            : Colors.orange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                onTap: () async {
                                  await _showLocationResolutionDialog(
                                    locationIssue,
                                  );
                                },
                              ),
                              SettingsTile(
                                icon: const Icon(Icons.wifi),
                                title: 'Wi-Fi',
                                subtitle: locationReady
                                    ? (isConnected
                                          ? wifiName
                                          : 'Not connected')
                                    : 'Turn on location to detect Wi-Fi name',
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
                                onTap: () async {
                                  if (!locationReady) {
                                    await _showLocationResolutionDialog(
                                      locationIssue,
                                    );
                                    return;
                                  }

                                  await AppSettings.openAppSettings(
                                    type: AppSettingsType.wifi,
                                  );
                                  await _refreshConnectivityState();
                                },
                              ),
                            ],
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
                                _linkingGoogle
                                    ? 'Connecting...'
                                    : hasGoogleProvider
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
                            onTap: hasGoogleProvider
                                ? null
                                : _linkGoogleAccount,
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
                      final shouldLogout = await showAppConfirmationDialog(
                        context,
                        title: 'Confirm Logout',
                        message: 'Are you sure you want to logout?',
                        cancelLabel: 'Cancel',
                        confirmLabel: 'Logout',
                        confirmColor: const Color(0xFFA31618),
                      );

                      if (shouldLogout) {
                        await FirebaseAuth.instance.signOut();
                        if (!mounted) return;
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

class _ConnectivityState {
  const _ConnectivityState({required this.locationIssue, this.wifiName});

  final LocationAccessIssue locationIssue;
  final String? wifiName;
}
