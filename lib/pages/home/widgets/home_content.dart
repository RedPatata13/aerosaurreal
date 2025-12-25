import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../dashboard/dashboard.dart';
import '../../monitoring/monitoring.dart';
import '../../insights/insights.dart';
import '../../device_management/device_management.dart';
import '../../settings.dart';

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
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _userDocStream;

  int _selectedIndex = 0;
  int _selectedDeviceIndex = 0;
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
      _handleLogoutAndRedirect();
      return;
    }

    _userDocStream = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .snapshots();
  }

  Future<void> _handleLogoutAndRedirect() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn.instance.disconnect();

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
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userDocStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleLogoutAndRedirect();
          });

          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'Error fetching user data: ${snapshot.error}. Logging out...',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleLogoutAndRedirect();
          });

          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'User data not found in database. Logging out...',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final data = snapshot.data!.data()!;
        final username = data['username'] ?? 'Unknown User';
        final devices = (data['devices'] as List?) ?? const [];
        final hasDevices = devices.isNotEmpty;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final uid = FirebaseAuth.instance.currentUser?.uid;

        if (uid == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleLogoutAndRedirect();
          });
          return const Scaffold(body: SizedBox.shrink());
        }

        if (hasDevices && _deviceState.isEmpty) {
          final initial = _defaultDevices();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _deviceState = initial);
          });
        }

        final devicesForUi = hasDevices ? _deviceState : const <Device>[];
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
                                    final current = _deviceState.isEmpty
                                        ? devicesForUi
                                        : _deviceState;
                                    _deviceState = current
                                        .map(
                                          (d) =>
                                              d.id == updated.id ? updated : d,
                                        )
                                        .toList(growable: false);
                                  });
                                },
                              )
                            else
                              const SizedBox.shrink(),
                            if (selectedDevice != null)
                              Monitoring(device: selectedDevice)
                            else
                              const SizedBox.shrink(),
                            if (selectedDevice != null)
                              Insights(device: selectedDevice)
                            else
                              const SizedBox.shrink(),
                          ],
                        )
                      : NoDeviceContent(
                          onRegisterDevice: () =>
                              _showRegisterDeviceDialog(uid),
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
      },
    );
  }
}
