import 'dart:ui';

import 'package:aerosaur/state/device_hub_controller.dart';
import 'package:aerosaur/state/user_store.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../components/navbar.dart';
import '../../../components/tutorial_showcase.dart';
import '../../../models/device.dart';
import '../../../routes/routes.dart';
import '../../../services/tutorial/app_tutorial_service.dart';
import '../../dashboard/dashboard.dart';
import '../../device_management/device_management_args.dart';
import '../../insights/insights.dart';
import '../../monitoring/monitoring.dart';
import '../../../services/api/analytics_api.dart';
import '../../../services/api/api_client.dart';
import '../../../services/api/control_api.dart';
import '../../../services/api/devices_api.dart';
import '../../../services/api/readings_api.dart';
import '../../../services/repositories/premium_repository.dart';
import 'home_header.dart';
import 'no_device_content.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> with WidgetsBindingObserver {
  late final PageController _pageController;
  late final DeviceHubController _controller;
  final AppTutorialService _tutorialService = AppTutorialService();
  final GlobalKey _tutorialHelpKey = GlobalKey();
  final GlobalKey _registerDeviceKey = GlobalKey();
  final GlobalKey _emptyStateRegisterKey = GlobalKey();
  final GlobalKey _notificationsKey = GlobalKey();
  final GlobalKey _settingsKey = GlobalKey();
  final GlobalKey _aqiKey = GlobalKey();
  final GlobalKey _devicesKey = GlobalKey();
  final GlobalKey _smartModeKey = GlobalKey();
  final GlobalKey _fanSpeedKey = GlobalKey();
  final GlobalKey _bottomNavKey = GlobalKey();
  bool _tutorialCheckStarted = false;
  bool _tutorialStartedThisSession = false;
  bool _premiumLoading = true;
  bool _premiumRefreshing = false;
  bool _isPremium = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _pageController = PageController();

    final api = context.read<ApiClient>();
    _controller = DeviceHubController(
      devicesApi: DevicesApi(api),
      readingsApi: ReadingsApi(api),
      controlApi: ControlApi(api),
      analyticsApi: AnalyticsApi(api),
    );

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleLogoutAndRedirect();
      });
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<UserStore>().loadOrCreate();
      await _refreshPremiumStatus(
        userId: currentUser.uid,
        showLoader: true,
      );
      await _controller.initialize();
    });
  }

  Future<void> _refreshPremiumStatus({
    required String userId,
    bool showLoader = false,
  }) async {
    if (_premiumRefreshing) {
      return;
    }

    if (showLoader && mounted) {
      setState(() {
        _premiumLoading = true;
      });
    }

    _premiumRefreshing = true;

    try {
      final status = await PremiumRepository(
        context.read<ApiClient>(),
      ).getPremiumStatus(userId);

      if (!mounted) return;
      setState(() {
        _isPremium = status['isPremium'] == true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isPremium = false;
      });
    } finally {
      _premiumRefreshing = false;
      if (mounted) {
        setState(() {
          _premiumLoading = false;
        });
      }
    }
  }

  Future<void> _handleLogoutAndRedirect() async {
    try {
      context.read<UserStore>().clear();
    } catch (_) {}

    await FirebaseAuth.instance.signOut();

    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {}

    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _openDeviceManagement({
    required String uid,
    required List<Device> devicesForUi,
  }) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.deviceManagement,
      arguments: DeviceManagementArgs(
        uid: uid,
        devices: devicesForUi,
        onDevicesChanged: (next) {
          if (!mounted) {
            return;
          }
          _controller.applyDeviceList(next);
        },
      ),
    );

    if (!mounted) return;
    await _controller.loadDevices(silent: true);
  }

  List<GlobalKey> _tutorialSteps({required bool hasDevices}) {
    return [
      _tutorialHelpKey,
      _registerDeviceKey,
      _notificationsKey,
      _settingsKey,
      if (hasDevices) ...[_aqiKey, _devicesKey, _smartModeKey, _fanSpeedKey],
      if (!hasDevices) _emptyStateRegisterKey,
      _bottomNavKey,
    ];
  }

  Future<void> _startTutorial({
    required bool hasDevices,
    bool markAsSeen = true,
  }) async {
    if (_controller.selectedPageIndex != 0) {
      await _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
      );
    }

    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ShowcaseView.get().startShowCase(_tutorialSteps(hasDevices: hasDevices));
    });

    _tutorialStartedThisSession = true;
    if (markAsSeen) {
      await _tutorialService.markHomeTourSeen();
    }
  }

  void _queueAutoTutorial({required bool hasDevices}) {
    if (_tutorialCheckStarted || _tutorialStartedThisSession) {
      return;
    }

    _tutorialCheckStarted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final hasSeenTutorial = await _tutorialService.hasSeenHomeTour();
      if (!mounted || hasSeenTutorial) return;
      await _startTutorial(hasDevices: hasDevices, markAsSeen: true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isForeground = state == AppLifecycleState.resumed;
    _controller.setForegroundActive(isForeground);

    if (!isForeground) {
      return;
    }

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return;
    }

    _refreshPremiumStatus(userId: userId);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<UserStore>();
    if (store.isLoading && !store.hasProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final username = store.username;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleLogoutAndRedirect();
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    if (_premiumLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.devicesLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (_controller.devicesError != null) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Failed to load devices.',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _controller.devicesError!,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 42,
                      child: OutlinedButton(
                        onPressed: () => _controller.loadDevices(),
                        child: const Text('Retry'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        final devicesForUi = _controller.devices;
        final hasDevices = devicesForUi.isNotEmpty;
        final selectedDevice = _controller.selectedDevice;

        return ShowCaseWidget(
          key: const ValueKey('home-tour-bubble-only-v2'),
          onFinish: () {
            _tutorialService.markHomeTourSeen();
          },
          onDismiss: (_) {
            _tutorialService.markHomeTourSeen();
          },
          disableBarrierInteraction: false,
          enableAutoScroll: true,
          blurValue: 1,
          builder: (_) {
            _queueAutoTutorial(hasDevices: hasDevices);

            return Scaffold(
              extendBody: true,
              body: SafeArea(
                child: Column(
                  children: [
                    HomeHeader(
                      username: username,
                      iconColor: isDark
                          ? Colors.white
                          : const Color(0xFF111827),
                      onRegisterDevice: () {
                        if (!hasDevices) {
                          _openDeviceManagement(
                            uid: uid,
                            devicesForUi: devicesForUi,
                          );
                          return;
                        }

                        _openDeviceManagement(
                          uid: uid,
                          devicesForUi: devicesForUi,
                        );
                      },
                      onShowTutorial: () {
                        _startTutorial(hasDevices: hasDevices);
                      },
                      tutorialButtonKey: _tutorialHelpKey,
                      addButtonKey: _registerDeviceKey,
                      notificationsButtonKey: _notificationsKey,
                      settingsButtonKey: _settingsKey,
                    ),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: (index) async {
                          await _controller.selectPage(index);
                        },
                        children: [
                          if (selectedDevice != null)
                            Dashboard(
                              devices: devicesForUi,
                              selectedDeviceIndex:
                                  _controller.selectedDeviceIndex,
                              onTogglePower: (deviceId, isOn) async {
                                final error = await _controller
                                    .setPowerForDevice(deviceId, isOn);
                                if (error != null && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(error)),
                                  );
                                }
                              },
                              onControlChanged: (deviceId, patch) async {
                                final error = await _controller
                                    .updateControlForDevice(deviceId, patch);
                                if (error != null && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(error)),
                                  );
                                }
                              },
                              onSelectDevice: (index) async {
                                await _controller.selectDevice(index);
                              },
                              onUpdateDevice: _controller.updateDevice,
                              onRefresh: _controller.refreshCurrentTab,
                              airQualityKey: _aqiKey,
                              devicesKey: _devicesKey,
                              smartModeKey: _smartModeKey,
                              fanSpeedKey: _fanSpeedKey,
                            )
                          else
                            NoDeviceContent(
                              onRegisterDevice: () {
                                _openDeviceManagement(
                                  uid: uid,
                                  devicesForUi: devicesForUi,
                                );
                              },
                              onLogout: _handleLogoutAndRedirect,
                              registerButtonKey: _emptyStateRegisterKey,
                            ),
                          _PremiumLockedPage(
                            locked: !_isPremium,
                            title: 'Premium Required',
                            message:
                                'Monitoring is available for premium subscribers only.',
                            onUnlock: () async {
                              await Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.premium);

                              if (!mounted) return;
                              final userId = FirebaseAuth.instance.currentUser?.uid;
                              if (userId == null) return;
                              await _refreshPremiumStatus(userId: userId);
                            },
                            child: selectedDevice != null
                                ? Monitoring(
                                    device: selectedDevice,
                                    onRefresh: _controller.refreshCurrentTab,
                                  )
                                : _NoDeviceFeatureContent(
                                    title: 'No device registered yet.',
                                    description:
                                        'Register a device to start viewing live monitoring data.',
                                    onRegisterDevice: () {
                                      _openDeviceManagement(
                                        uid: uid,
                                        devicesForUi: devicesForUi,
                                      );
                                    },
                                  ),
                          ),
                          _PremiumLockedPage(
                            locked: !_isPremium,
                            title: 'Premium Required',
                            message:
                                'Insights is available for premium subscribers only.',
                            onUnlock: () async {
                              await Navigator.of(
                                context,
                              ).pushNamed(AppRoutes.premium);

                              if (!mounted) return;
                              final userId = FirebaseAuth.instance.currentUser?.uid;
                              if (userId == null) return;
                              await _refreshPremiumStatus(userId: userId);
                            },
                            child: selectedDevice != null
                                ? Insights(
                                    device: selectedDevice,
                                    onRefresh: _controller.refreshCurrentTab,
                                  )
                                : _NoDeviceFeatureContent(
                                    title: 'No device registered yet.',
                                    description:
                                        'Register a device to unlock air quality insights and trends.',
                                    onRegisterDevice: () {
                                      _openDeviceManagement(
                                        uid: uid,
                                        devicesForUi: devicesForUi,
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: wrapTutorialShowcase(
                child: CustomBottomNav(
                  currentIndex: _controller.selectedPageIndex,
                  onTap: (value) {
                    if (value == _controller.selectedPageIndex) return;

                    _pageController.animateToPage(
                      value,
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                    );
                  },
                ),
                showcaseKey: _bottomNavKey,
                title: 'Navigate between pages',
                description:
                    'Use these tabs to move between Dashboard, Monitoring, and Insights. Monitoring shows live readings, while Insights helps you review trends.',
                shapeBorder: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _PremiumLockedPage extends StatelessWidget {
  const _PremiumLockedPage({
    required this.locked,
    required this.title,
    required this.message,
    required this.onUnlock,
    required this.child,
  });

  final bool locked;
  final String title;
  final String message;
  final VoidCallback onUnlock;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!locked) {
      return child;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: child,
          ),
        ),
        Container(color: theme.scaffoldBackgroundColor.withValues(alpha: 0.45)),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Material(
                color: colorScheme.surface,
                elevation: 8,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: onUnlock,
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          size: 34,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.72,
                            ),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: onUnlock,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Text('Get Premium'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NoDeviceFeatureContent extends StatelessWidget {
  const _NoDeviceFeatureContent({
    required this.title,
    required this.description,
    required this.onRegisterDevice,
  });

  final String title;
  final String description;
  final VoidCallback onRegisterDevice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.devices_other_rounded,
                size: 34,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 14),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: onRegisterDevice,
                icon: const Icon(Icons.link_rounded),
                label: const Text('Register Device'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
