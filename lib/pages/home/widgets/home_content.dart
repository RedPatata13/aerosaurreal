import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';
import 'package:aerosaur_2nd_sem/state/user_store.dart';
import '../../dashboard/dashboard.dart';
import '../../monitoring/monitoring.dart';
import '../../insights/insights.dart';
import '../../device_management/device_management.dart';
import '../../../models/device.dart';
import '../../../components/navbar.dart';
import 'home_header.dart';
import 'no_device_content.dart';
import '../dialogs/register_device_dialog.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  int _selectedIndex = 0;
  int _selectedDeviceIndex = 0;

  // temp data
  List<Device> _deviceState = const [];

  static const _defaultDeviceSpecs = [
    {'id': 'AV501', 'name': 'Room 301'},
    {'id': 'AV502', 'name': 'Room 302'},
    {'id': 'AV503', 'name': 'Room 303'},
  ];

  @override
  void initState() {
    super.initState();

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleLogoutAndRedirect();
      });
      return;
    }

    // temp
    _deviceState = _defaultDevices();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await context.read<UserStore>().loadOrCreate();
    });
  }

  Future<void> _refreshCurrentTab() async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() {
      // fetch data
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

  void _showRegisterDeviceDialog(String uid) {
    showDialog<void>(
      context: context,
      builder: (context) => RegisterDeviceDialog(uid: uid),
    );
  }

  List<Device> _defaultDevices() {
    return List.generate(_defaultDeviceSpecs.length, (index) {
      final spec = _defaultDeviceSpecs[index];
      return Device.demoFromDb(
        id: spec['id']!,
        name: spec['name']!,
        seed: index,
      );
    });
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

    final devicesForUi = _deviceState;
    final hasDevices = devicesForUi.isNotEmpty;

    final safeSelectedIndex = devicesForUi.isEmpty
        ? 0
        : _selectedDeviceIndex.clamp(0, devicesForUi.length - 1);

    final selectedDevice = devicesForUi.isEmpty
        ? null
        : devicesForUi[safeSelectedIndex];

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
                  _showRegisterDeviceDialog(uid);
                  return;
                }

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DeviceManagementPage(
                      uid: uid,
                      devices: devicesForUi,
                      onDevicesChanged: (next) {
                        setState(() {
                          _deviceState = next;
                          if (_selectedDeviceIndex >= next.length) {
                            _selectedDeviceIndex = 0;
                          }
                        });
                      },
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: hasDevices
                  ? IndexedStack(
                      index: _selectedIndex,
                      children: [
                        if (selectedDevice != null)
                          Dashboard(
                            devices: devicesForUi,
                            selectedDeviceIndex: safeSelectedIndex,
                            onSelectDevice: (index) {
                              setState(() {
                                _selectedDeviceIndex = index.clamp(
                                  0,
                                  devicesForUi.length - 1,
                                );
                              });
                            },
                            onUpdateDevice: (updated) {
                              setState(() {
                                _deviceState = _deviceState
                                    .map(
                                      (d) => d.id == updated.id ? updated : d,
                                    )
                                    .toList(growable: false);
                              });
                            },
                            onRefresh: _refreshCurrentTab,
                          )
                        else
                          const SizedBox.shrink(),
                        if (selectedDevice != null)
                          Monitoring(
                            device: selectedDevice,
                            onRefresh: _refreshCurrentTab,
                          )
                        else
                          const SizedBox.shrink(),
                        if (selectedDevice != null)
                          Insights(
                            device: selectedDevice,
                            onRefresh: _refreshCurrentTab,
                          )
                        else
                          const SizedBox.shrink(),
                      ],
                    )
                  : NoDeviceContent(
                      onRegisterDevice: () => _showRegisterDeviceDialog(uid),
                      onLogout: _handleLogoutAndRedirect,
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: (value) {
          setState(() {
            _selectedIndex = value;
          });
        },
      ),
    );
  }
}
