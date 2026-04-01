import 'package:aerosaur_2nd_sem/state/device_hub_controller.dart';
import 'package:aerosaur_2nd_sem/state/user_store.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../../../components/navbar.dart';
import '../../../routes/routes.dart';
import '../../dashboard/dashboard.dart';
import '../../device_management/device_management_args.dart';
import '../../insights/insights.dart';
import '../../monitoring/monitoring.dart';
import '../../../services/api/analytics_api.dart';
import '../../../services/api/api_client.dart';
import '../../../services/api/control_api.dart';
import '../../../services/api/devices_api.dart';
import '../../../services/api/readings_api.dart';
import 'home_header.dart';
import 'no_device_content.dart';
import '../dialogs/register_device_dialog.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> with WidgetsBindingObserver {
  late final PageController _pageController;
  late final DeviceHubController _controller;

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
      await _controller.initialize();
    });
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

  void _showRegisterDeviceDialog() {
    showDialog<bool>(
      context: context,
      builder: (context) => const RegisterDeviceDialog(),
    ).then((ok) async {
      if (ok == true) {
        await _controller.loadDevices();
      }
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

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        if (_controller.devicesLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                    Text(_controller.devicesError!, textAlign: TextAlign.center),
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

        return Scaffold(
          extendBody: true,
          body: SafeArea(
            child: Column(
              children: [
                HomeHeader(
                  username: username,
                  iconColor: isDark ? Colors.white : const Color(0xFF111827),
                  onRegisterDevice: () {
                    if (!hasDevices) {
                      _showRegisterDeviceDialog();
                      return;
                    }

                    Navigator.of(context)
                        .pushNamed(
                          AppRoutes.deviceManagement,
                          arguments: DeviceManagementArgs(
                            uid: uid,
                            devices: devicesForUi,
                            onDevicesChanged: _controller.applyDeviceList,
                          ),
                        )
                        .then((_) async {
                          await _controller.loadDevices(silent: true);
                        });
                  },
                ),
                Expanded(
                  child: hasDevices
                      ? PageView(
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
                                onControlChanged: (patch) async {
                                  final error = await _controller
                                      .updateControlForSelectedDevice(patch);
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
                              )
                            else
                              const SizedBox.shrink(),
                            if (selectedDevice != null)
                              Monitoring(
                                device: selectedDevice,
                                onRefresh: _controller.refreshCurrentTab,
                              )
                            else
                              const SizedBox.shrink(),
                            if (selectedDevice != null)
                              Insights(
                                device: selectedDevice,
                                onRefresh: _controller.refreshCurrentTab,
                              )
                            else
                              const SizedBox.shrink(),
                          ],
                        )
                      : NoDeviceContent(
                          onRegisterDevice: _showRegisterDeviceDialog,
                          onLogout: _handleLogoutAndRedirect,
                        ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: CustomBottomNav(
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
        );
      },
    );
  }
}
