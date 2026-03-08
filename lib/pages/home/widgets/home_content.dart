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
import '/services/api/devices_api.dart';
import '/services/api/readings_api.dart';
import '/services/api/api_client.dart';
import 'dart:async';
import '/services/api/control_api.dart';
import '/services/api/endpoints.dart';
import '/services/api/analytics_api.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  int _selectedIndex = 0;
  int _selectedDeviceIndex = 0;
  Timer? _pollTimer;
  bool _loadingLatest = false;
  int? _lastUpdatedAtSec;
  late final PageController _pageController;
  late final DevicesApi _devicesApi;
  late final ReadingsApi _readingsApi;
  late final ControlApi _controlApi;
  late final AnalyticsApi _analyticsApi;
  final Set<String> _controlPending = <String>{};
  bool _devicesLoading = true;
  String? _devicesError;
  List<Device> _deviceState = const [];
  DateTime _lastUpdated = DateTime.now();

  @override
  void initState() {
    super.initState();

    _pageController = PageController(initialPage: _selectedIndex);

    final api = context.read<ApiClient>();
    _devicesApi = DevicesApi(api);
    _readingsApi = ReadingsApi(api);
    _controlApi = ControlApi(api);
    _analyticsApi = AnalyticsApi(api);

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
      await _loadDevices();
    });
  }

  Future<void> _loadLatestForSelectedDevice({bool silent = false}) async {
    if (_deviceState.isEmpty) return;
    if (_loadingLatest) return;
    _loadingLatest = true;

    final index = _selectedDeviceIndex.clamp(0, _deviceState.length - 1);
    final device = _deviceState[index];

    try {
      final latest = await _readingsApi.getLatest(device.id);
      final updatedAtSec = (latest['updatedAtSec'] as num?)?.toInt();

      debugPrint("LATEST JSON: $latest");

      if (silent && updatedAtSec != null && updatedAtSec == _lastUpdatedAtSec) {
        return;
      }
      _lastUpdatedAtSec = updatedAtSec;
      _lastUpdated = DateTime.now();

      final normalized = <String, dynamic>{
        ...latest,
        'tempC': latest['tempC'] ?? latest['temperature'] ?? latest['temp'],
        'vocsPpm': latest['vocsPpm'] ?? latest['voc_raw'] ?? latest['voc'],
        'harmfulGasDetected':
            latest['harmfulGasDetected'] ??
            latest['gas_alert'] ??
            latest['gasAlert'],

        'pm25': latest['pm25'] ?? latest['pm2_5'] ?? latest['pm2.5'],
        'pm10': latest['pm10'] ?? latest['pm_10'] ?? latest['pm10_ugm3'],

        'aqi': latest['aqi'],
        'aqiCategory': latest['aqiCategory'] ?? latest['aqiLabel'],
        'aqiPercent': latest['aqiPercent'],

        'updatedAtSec': updatedAtSec,
      };

      if (!mounted) return;
      setState(() {
        _deviceState = _deviceState
            .map(
              (d) => d.id == device.id ? d.applyLatestReading(normalized) : d,
            )
            .toList(growable: false);
      });
    } catch (e) {
      if (!silent) {
        debugPrint('❌ getLatest failed for ${device.id}: $e');
      }
    } finally {
      _loadingLatest = false;
    }
  }

  Future<void> _loadAnalyticsForSelectedDevice() async {
    if (_deviceState.isEmpty) return;

    final index = _selectedDeviceIndex.clamp(0, _deviceState.length - 1);
    final device = _deviceState[index];

    try {
      final data = await _analyticsApi.getAnalytics7d(device.id);

      debugPrint("ANALYTICS RESPONSE: $data");

      final summary = data['summary'] ?? {};
      final trend = data['aqiTrend'] ?? [];
      final usage = data['usageTrend'] ?? [];

      final peakList = trend
          .map<int>((e) => (e['peakAQI'] as num? ?? 0).toInt())
          .toList();

      final avgList = trend
          .map<int>((e) => (e['avgAQI'] as num? ?? 0).toInt())
          .toList();

      final usageList = usage
          .map<double>((e) => (e['hours'] as num? ?? 0).toDouble())
          .toList();

      if (!mounted) return;

      setState(() {
        _deviceState = _deviceState
            .map((d) {
              if (d.id != device.id) return d;

              return d.copyWith(
                aqiPeak7d: peakList,
                aqiAverage7d: avgList,
                purifierUsageHours7d: usageList,
                totalUsageHours7d: (summary['totalUsageHours7d'] ?? 0)
                    .toDouble(),
                dailyUsageHours: usageList.isNotEmpty ? usageList.last : 0,
                timeInGoodOrModeratePercentToday:
                    summary['goodPercentage'] ?? 0,
                directHoursToday: (summary['directHoursToday'] ?? 0).toDouble(),
                energySavedPercent: summary['energySavedPercent'] ?? 0,
              );
            })
            .toList(growable: false);
      });
    } catch (e) {
      debugPrint("❌ Analytics load failed: $e");
    }
  }

  Future<void> _loadControlForDevice(
    String deviceId, {
    bool silent = true,
  }) async {
    try {
      final control = await _controlApi.getControl(deviceId);

      if (!mounted) return;
      setState(() {
        _deviceState = _deviceState
            .map((d) => d.id == deviceId ? d.copyWithFromPatch(control) : d)
            .toList(growable: false);
      });
    } catch (e) {
      if (!silent) {
        debugPrint('❌ getControl failed for $deviceId: $e');
      }
    }
  }

  Future<void> _updateControlForSelectedDevice(
    Map<String, dynamic> patch,
  ) async {
    if (_deviceState.isEmpty) return;

    final index = _selectedDeviceIndex.clamp(0, _deviceState.length - 1);
    final device = _deviceState[index];
    final deviceId = device.id;

    debugPrint("CURRENT UID: ${FirebaseAuth.instance.currentUser?.uid}");
    debugPrint("TRYING CONTROL FOR DEVICE: $deviceId");

    if (_controlPending.contains(deviceId)) return;

    setState(() {
      _controlPending.add(deviceId);
      _deviceState = _deviceState
          .map((d) => d.id == deviceId ? d.copyWithFromPatch(patch) : d)
          .toList(growable: false);
    });

    try {
      final updated = await _controlApi.updateControl(deviceId, patch: patch);

      if (!mounted) return;
      setState(() {
        _deviceState = _deviceState
            .map((d) => d.id == deviceId ? d.copyWithFromPatch(updated) : d)
            .toList(growable: false);
      });
    } catch (e) {
      await _loadControlForDevice(deviceId, silent: false);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Control update failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _controlPending.remove(deviceId));
      }
    }
  }

  Future<void> _loadDevices() async {
    try {
      setState(() {
        _devicesLoading = true;
        _devicesError = null;
      });

      final items = await _devicesApi.listDevices();
      final devices = items.map(Device.fromApi).toList(growable: false);

      if (!mounted) return;

      setState(() {
        _deviceState = devices;
        _devicesLoading = false;

        if (_selectedDeviceIndex >= devices.length) {
          _selectedDeviceIndex = 0;
        }
      });

      if (devices.isNotEmpty) {
        final selectedIndex = _selectedDeviceIndex.clamp(0, devices.length - 1);
        await _loadControlForDevice(devices[selectedIndex].id);
      }

      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        await _loadLatestForSelectedDevice(silent: true);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _devicesError = e.toString();
        _devicesLoading = false;
      });
    }
  }

  Future<void> _refreshCurrentTab() async {
    await _loadLatestForSelectedDevice();

    if (_selectedIndex == 2) {
      await _loadAnalyticsForSelectedDevice();
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

  void _showRegisterDeviceDialog(String uid) {
    showDialog<bool>(
      context: context,
      builder: (context) => RegisterDeviceDialog(uid: uid),
    ).then((ok) async {
      if (ok == true) await _loadDevices();
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
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

    if (_devicesLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_devicesError != null) {
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
                Text(_devicesError!, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                SizedBox(
                  height: 42,
                  child: OutlinedButton(
                    onPressed: _loadDevices,
                    child: const Text('Retry'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
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

                Navigator.of(context)
                    .push(
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
                    )
                    .then((_) async {
                      await _loadDevices();
                    });
              },
            ),
            Expanded(
              child: hasDevices
                  ? PageView(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (i) async {
                        setState(() => _selectedIndex = i);
                        if (i == 2) {
                          await _loadAnalyticsForSelectedDevice();
                        }
                      },
                      children: [
                        if (selectedDevice != null)
                          Dashboard(
                            devices: devicesForUi,
                            selectedDeviceIndex: safeSelectedIndex,
                            onControlChanged: (patch) =>
                                _updateControlForSelectedDevice(patch),
                            onSelectDevice: (index) async {
                              setState(() {
                                _selectedDeviceIndex = index.clamp(
                                  0,
                                  devicesForUi.length - 1,
                                );
                              });

                              final selected =
                                  devicesForUi[_selectedDeviceIndex];
                              await _loadLatestForSelectedDevice();
                              await _loadControlForDevice(selected.id);
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
          if (value == _selectedIndex) return;

          _pageController.animateToPage(
            value,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
          );
        },
      ),
    );
  }
}
