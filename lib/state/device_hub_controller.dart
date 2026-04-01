import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/device.dart';
import '../services/api/analytics_api.dart';
import '../services/api/control_api.dart';
import '../services/api/devices_api.dart';
import '../services/api/readings_api.dart';

class DeviceHubController extends ChangeNotifier {
  static const Duration _pollInterval = Duration(seconds: 8);
  static const Duration _analyticsCacheTtl = Duration(minutes: 2);

  DeviceHubController({
    required DevicesApi devicesApi,
    required ReadingsApi readingsApi,
    required ControlApi controlApi,
    required AnalyticsApi analyticsApi,
  }) : _devicesApi = devicesApi,
       _readingsApi = readingsApi,
       _controlApi = controlApi,
       _analyticsApi = analyticsApi;

  final DevicesApi _devicesApi;
  final ReadingsApi _readingsApi;
  final ControlApi _controlApi;
  final AnalyticsApi _analyticsApi;

  final Set<String> _controlPending = <String>{};
  final Set<String> _latestLoading = <String>{};
  final Set<String> _analyticsLoading = <String>{};
  final Map<String, int?> _lastUpdatedAtSecByDevice = <String, int?>{};
  final Map<String, DateTime> _lastAnalyticsLoadedAtByDevice = <String, DateTime>{};

  Timer? _pollTimer;
  bool _initialized = false;
  bool _devicesLoading = true;
  bool _isForeground = true;
  String? _devicesError;
  List<Device> _devices = const [];
  int _selectedPageIndex = 0;
  String? _selectedDeviceId;

  bool get initialized => _initialized;
  bool get devicesLoading => _devicesLoading;
  String? get devicesError => _devicesError;
  List<Device> get devices => _devices;
  int get selectedPageIndex => _selectedPageIndex;

  int get selectedDeviceIndex {
    if (_devices.isEmpty) {
      return 0;
    }

    final index = _devices.indexWhere((device) => device.id == _selectedDeviceId);
    return index >= 0 ? index : 0;
  }

  Device? get selectedDevice {
    if (_devices.isEmpty) {
      return null;
    }
    return _devices[selectedDeviceIndex];
  }

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    await loadDevices();
  }

  Future<void> loadDevices({bool silent = false}) async {
    try {
      if (!silent) {
        _devicesLoading = true;
        _devicesError = null;
        notifyListeners();
      }

      final previousSelectedId = _selectedDeviceId;
      final items = await _devicesApi.listDevices();
      final nextDevices = items.map(Device.fromApi).toList(growable: false);

      _devices = nextDevices;
      _devicesLoading = false;
      _devicesError = null;

      if (_devices.isEmpty) {
        _selectedDeviceId = null;
      } else if (previousSelectedId != null &&
          _devices.any((device) => device.id == previousSelectedId)) {
        _selectedDeviceId = previousSelectedId;
      } else {
        _selectedDeviceId = _devices.first.id;
      }

      _pruneCaches();
      notifyListeners();

      if (selectedDevice != null) {
        await Future.wait([
          loadLatestForSelectedDevice(silent: true),
          loadControlForDevice(selectedDevice!.id),
          if (_selectedPageIndex == 2) loadAnalyticsForSelectedDevice(),
        ]);
      }

      _restartPolling();
    } catch (e) {
      _devicesLoading = false;
      _devicesError = e.toString();
      notifyListeners();
    }
  }

  Future<void> refreshCurrentTab() async {
    final device = selectedDevice;
    if (device == null) {
      return;
    }

    await Future.wait([
      loadLatestForSelectedDevice(),
      loadControlForDevice(device.id),
      if (_selectedPageIndex == 2) loadAnalyticsForSelectedDevice(force: true),
    ]);
  }

  Future<void> selectPage(int index) async {
    if (_selectedPageIndex == index) {
      return;
    }

    _selectedPageIndex = index;
    notifyListeners();
    _restartPolling();

    if (index == 2) {
      await loadAnalyticsForSelectedDevice();
    }
  }

  Future<void> selectDevice(int index) async {
    if (_devices.isEmpty) {
      return;
    }

    final safeIndex = index.clamp(0, _devices.length - 1);
    final nextDevice = _devices[safeIndex];

    if (_selectedDeviceId == nextDevice.id) {
      return;
    }

    _selectedDeviceId = nextDevice.id;
    notifyListeners();

    await Future.wait([
      loadLatestForSelectedDevice(force: true),
      loadControlForDevice(nextDevice.id),
      if (_selectedPageIndex == 2) loadAnalyticsForSelectedDevice(),
    ]);
  }

  Future<void> loadLatestForSelectedDevice({
    bool silent = false,
    bool force = false,
  }) async {
    final device = selectedDevice;
    if (device == null) {
      return;
    }

    if (_latestLoading.contains(device.id)) {
      return;
    }
    _latestLoading.add(device.id);

    try {
      final latest = await _readingsApi.getLatest(device.id);
      final updatedAtSec = (latest['updatedAtSec'] as num?)?.toInt();

      if (!force &&
          silent &&
          updatedAtSec != null &&
          _lastUpdatedAtSecByDevice[device.id] == updatedAtSec) {
        return;
      }

      _lastUpdatedAtSecByDevice[device.id] = updatedAtSec;

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

      _replaceDevice(
        device.id,
        (existing) => existing.applyLatestReading(normalized),
      );
    } catch (e) {
      if (!silent) {
        debugPrint('getLatest failed for ${device.id}: $e');
      }
    } finally {
      _latestLoading.remove(device.id);
    }
  }

  Future<void> loadAnalyticsForSelectedDevice({bool force = false}) async {
    final device = selectedDevice;
    if (device == null || _analyticsLoading.contains(device.id)) {
      return;
    }

    final lastLoadedAt = _lastAnalyticsLoadedAtByDevice[device.id];
    if (!force &&
        lastLoadedAt != null &&
        DateTime.now().difference(lastLoadedAt) < _analyticsCacheTtl) {
      return;
    }
    _analyticsLoading.add(device.id);

    try {
      final data = await _analyticsApi.getAnalytics7d(device.id);
      final summary = (data['summary'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final trend = (data['aqiTrend'] as List?) ?? const [];
      final usage = (data['usageTrend'] as List?) ?? const [];

      final peakList = trend
          .whereType<Map>()
          .map<int>((e) => (e['peakAQI'] as num? ?? 0).toInt())
          .toList(growable: false);

      final avgList = trend
          .whereType<Map>()
          .map<int>((e) => (e['avgAQI'] as num? ?? 0).toInt())
          .toList(growable: false);

      final usageList = usage
          .whereType<Map>()
          .map<double>((e) => (e['hours'] as num? ?? 0).toDouble())
          .toList(growable: false);

      final totalUsageHours = usageList.fold<double>(
        0,
        (sum, value) => sum + value,
      );

      _replaceDevice(
        device.id,
        (existing) => existing.copyWith(
          aqiPeak7d: peakList,
          aqiAverage7d: avgList,
          purifierUsageHours7d: usageList,
          totalUsageHours7d:
              (summary['totalUsageHours7d'] as num?)?.toDouble() ??
              totalUsageHours,
          dailyUsageHours: usageList.isNotEmpty ? usageList.last : 0,
          timeInGoodOrModeratePercentToday:
              (summary['goodPercentage'] as num? ?? 0).toInt(),
          directHoursToday:
              (summary['directHoursToday'] as num? ?? 0).toDouble(),
          energySavedPercent:
              (summary['energySavedPercent'] as num? ?? 0).toInt(),
        ),
      );
      _lastAnalyticsLoadedAtByDevice[device.id] = DateTime.now();
    } catch (e) {
      debugPrint('Analytics load failed for ${device.id}: $e');
    } finally {
      _analyticsLoading.remove(device.id);
    }
  }

  Future<void> loadControlForDevice(String deviceId, {bool silent = true}) async {
    try {
      final control = await _controlApi.getControl(deviceId);
      _replaceDevice(
        deviceId,
        (existing) => existing.copyWithFromPatch(control),
      );
    } catch (e) {
      if (!silent) {
        debugPrint('getControl failed for $deviceId: $e');
      }
    }
  }

  Future<String?> updateControlForSelectedDevice(
    Map<String, dynamic> patch,
  ) async {
    final device = selectedDevice;
    if (device == null) {
      return null;
    }

    final deviceId = device.id;
    if (_controlPending.contains(deviceId)) {
      return null;
    }

    _controlPending.add(deviceId);
    _replaceDevice(
      deviceId,
      (existing) => existing.copyWithFromPatch(patch),
    );

    try {
      final res = await _controlApi.updateControl(deviceId, patch: patch);
      final updated = (res['data'] as Map?)?.cast<String, dynamic>() ?? res;
      _replaceDevice(
        deviceId,
        (existing) => existing.copyWithFromPatch(updated),
      );
      return null;
    } catch (e) {
      await loadControlForDevice(deviceId, silent: false);
      return 'Control update failed: $e';
    } finally {
      _controlPending.remove(deviceId);
    }
  }

  void applyDeviceList(List<Device> next) {
    final previousSelectedId = _selectedDeviceId;
    _devices = List<Device>.unmodifiable(next);

    if (_devices.isEmpty) {
      _selectedDeviceId = null;
    } else if (previousSelectedId != null &&
        _devices.any((device) => device.id == previousSelectedId)) {
      _selectedDeviceId = previousSelectedId;
    } else {
      _selectedDeviceId = _devices.first.id;
    }

    _pruneCaches();
    notifyListeners();
    _restartPolling();
  }

  void setForegroundActive(bool isForeground) {
    if (_isForeground == isForeground) {
      return;
    }
    _isForeground = isForeground;
    _restartPolling();
  }

  void updateDevice(Device updated) {
    _replaceDevice(updated.id, (_) => updated);
  }

  void _replaceDevice(String deviceId, Device Function(Device current) builder) {
    final index = _devices.indexWhere((device) => device.id == deviceId);
    if (index < 0) {
      return;
    }

    final next = _devices.toList(growable: false);
    next[index] = builder(next[index]);
    _devices = next;
    notifyListeners();
  }

  void _restartPolling() {
    _pollTimer?.cancel();
    if (_devices.isEmpty || !_isForeground || _selectedPageIndex == 2) {
      return;
    }

    _pollTimer = Timer.periodic(_pollInterval, (_) async {
      await loadLatestForSelectedDevice(silent: true);
    });
  }

  void _pruneCaches() {
    final validIds = _devices.map((device) => device.id).toSet();
    _lastUpdatedAtSecByDevice.removeWhere((key, _) => !validIds.contains(key));
    _lastAnalyticsLoadedAtByDevice.removeWhere(
      (key, _) => !validIds.contains(key),
    );
    _latestLoading.removeWhere((key) => !validIds.contains(key));
    _analyticsLoading.removeWhere((key) => !validIds.contains(key));
    _controlPending.removeWhere((key) => !validIds.contains(key));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
