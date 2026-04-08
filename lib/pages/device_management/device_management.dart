import 'package:aerosaur/routes/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/app_dialogs.dart';
import '../../components/wifi_password_dialog.dart';
import '../../models/device.dart';
import '../../services/api/api_client.dart';
import '../../services/api/devices_api.dart';
import '../../services/device/device_setup_service.dart';
import '../../services/location/location_access_service.dart';
import '../home/widgets/home_header.dart';
import 'device_details_page.dart';
import 'widgets/device_row.dart';
import 'widgets/filled_input.dart';

class DeviceManagementPage extends StatefulWidget {
  final String uid;
  final List<Device> devices;
  final ValueChanged<List<Device>> onDevicesChanged;

  const DeviceManagementPage({
    super.key,
    required this.uid,
    required this.devices,
    required this.onDevicesChanged,
  });

  @override
  State<DeviceManagementPage> createState() => _DeviceManagementPageState();
}

class _DeviceManagementPageState extends State<DeviceManagementPage> {
  final _deviceIdController = TextEditingController();
  final _deviceNameController = TextEditingController();

  late final DevicesApi _devicesApi;
  late final DeviceSetupService _setupService;

  bool _saving = false;
  bool _loading = true;
  String? _error;

  List<Device> _devices = [];

  @override
  void initState() {
    super.initState();
    final apiClient = context.read<ApiClient>();
    _devicesApi = DevicesApi(apiClient);
    _setupService = DeviceSetupService(_devicesApi);
    _devices = List<Device>.from(widget.devices);
    _loading = widget.devices.isEmpty;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadDevices(silent: widget.devices.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _loadDevices({bool silent = false}) async {
    try {
      if (!silent) {
        setState(() {
          _loading = true;
          _error = null;
        });
      }

      final items = await _devicesApi.listDevices();
      final next = items.map(Device.fromApi).toList(growable: false);

      if (!mounted) return;
      setState(() {
        _devices = next;
        _loading = false;
      });

      widget.onDevicesChanged(next);
    } catch (e) {
      if (!mounted) return;
      if (!silent || _devices.isEmpty) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _refreshDevices() => _loadDevices();

  Future<void> _submitNewDevice({
    String? rawCode,
    bool openProvisionAfterRegister = true,
  }) async {
    final rawInput = rawCode ?? _deviceIdController.text.trim();
    final name = _deviceNameController.text.trim();

    if (rawInput.isEmpty || _saving) {
      await showAppMessageDialog(
        context,
        title: 'Device ID Required',
        message: 'Enter or scan a device ID before registering.',
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final registered = await _setupService.registerDevice(
        rawCode: rawInput,
        name: name.isEmpty ? null : name,
      );
      await _loadDevices(silent: _devices.isNotEmpty);

      if (!mounted) return;

      _deviceIdController.clear();
      _deviceNameController.clear();
      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Device ${registered.id} registered.')),
      );

      if (openProvisionAfterRegister) {
        await _provisionAfterRegistration(registered.id);
      }
    } on FormatException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);

      await showAppMessageDialog(
        context,
        title: 'Invalid Device ID',
        message: e.message,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add device: $e')));
    }
  }

  Future<void> _provisionAfterRegistration(String deviceId) async {
    await _showWifiPasswordDialog(deviceId);
  }

  Future<void> _showWifiPasswordDialog(String deviceId) async {
    final wifiName = await _setupService.getSuggestedWifiName();
    if (wifiName == null || wifiName.isEmpty) {
      if (!mounted) return;
      final locationIssue = await LocationAccessService.getIssue();
      if (locationIssue != LocationAccessIssue.none) {
        final shouldOpen = await showAppConfirmationDialog(
          context,
          title: locationIssue == LocationAccessIssue.serviceDisabled
              ? 'Turn On Location'
              : 'Location Permission Needed',
          message: locationIssue == LocationAccessIssue.serviceDisabled
              ? 'Your phone location is turned off. Enable it so Aerosaur can detect your Wi-Fi and continue device setup.'
              : 'Allow location access so Aerosaur can detect your Wi-Fi and continue device setup.',
          cancelLabel: 'Close',
          confirmLabel: locationIssue == LocationAccessIssue.serviceDisabled
              ? 'Open Location'
              : 'Open Settings',
        );
        if (shouldOpen) {
          await LocationAccessService.openResolution(locationIssue);
        }
        return;
      }
      await showAppMessageDialog(
        context,
        title: 'Wi-Fi Required',
        message: 'Connect your phone to Wi-Fi first.',
      );
      return;
    }

    final result = await showDialog<WifiPasswordDialogResult>(
      context: context,
      builder: (_) => WifiPasswordDialog(
        title: 'Provision Wi-Fi',
        wifiName: wifiName,
        actionLabel: 'Provision',
      ),
    );

    if (result == null) return;

    final pass = result.password;

    if (pass.isEmpty) {
      if (!mounted) return;
      await showAppMessageDialog(
        context,
        title: 'Password Required',
        message: 'Wi-Fi password is required.',
      );
      return;
    }

    try {
      await _setupService.provisionWifi(
        rawCode: deviceId,
        ssid: wifiName,
        pass: pass,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Provision sent! Device will reboot and connect.'),
        ),
      );

      await Future.delayed(const Duration(seconds: 3));
      await _loadDevices();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Provision failed: $e')));
    }
  }

  Future<void> _openDeviceDetails(Device device) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => DeviceDetailsPage(device: device)),
    );

    if (mounted) {
      await _loadDevices(silent: true);
    }
  }

  Future<void> _openQrScanner() async {
    final result = await Navigator.pushNamed(context, AppRoutes.qrScanner);

    if (result is String && result.trim().isNotEmpty) {
      _deviceIdController.text = result.trim();

      String? registeredDeviceId;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      try {
        try {
          final registered = await _setupService.registerDevice(
            rawCode: result.trim(),
            name: _deviceNameController.text.trim().isEmpty
                ? null
                : _deviceNameController.text.trim(),
          );
          registeredDeviceId = registered.id;
          await _loadDevices(silent: _devices.isNotEmpty);

          if (!mounted) return;
          _deviceIdController.clear();
          _deviceNameController.clear();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Device ${registered.id} registered.')),
          );
        } on FormatException catch (e) {
          if (!mounted) return;
          await showAppMessageDialog(
            context,
            title: 'Invalid Device ID',
            message: e.message,
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to add device: $e')));
        }
      } finally {
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      }

      if (registeredDeviceId != null && mounted) {
        await _provisionAfterRegistration(registeredDeviceId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.displayName ?? 'User';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            HomeHeader(
              username: username,
              iconColor: theme.colorScheme.onSurface,
              onRegisterDevice: () {},
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: RefreshIndicator(
                  onRefresh: _refreshDevices,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Device Management',
                            style:
                                (theme.textTheme.titleMedium ??
                                        const TextStyle())
                                    .copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          FilledInput(
                            controller: _deviceIdController,
                            fill: theme.inputDecorationTheme.fillColor!,
                            hint: 'Enter Device ID (e.g. AIR123)',
                          ),
                          const SizedBox(height: 10),
                          FilledInput(
                            controller: _deviceNameController,
                            fill: theme.inputDecorationTheme.fillColor!,
                            hint: 'Enter Device Name (optional)',
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 47,
                            child: ElevatedButton(
                              onPressed: _saving
                                  ? null
                                  : () => _submitNewDevice(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                _saving ? 'Adding...' : 'Register Device',
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 47,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.qr_code_scanner),
                              label: const Text('Scan QR Code'),
                              onPressed: _openQrScanner,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Divider(color: theme.dividerColor, height: 1),
                          const SizedBox(height: 14),
                          if (_loading)
                            Text(
                              'Loading devices...',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (_error != null)
                            Text(
                              _error!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.red,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          const SizedBox(height: 10),
                          Text(
                            'Registered Devices',
                            style:
                                (theme.textTheme.bodyMedium ??
                                        const TextStyle())
                                    .copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                          ),
                          const SizedBox(height: 10),
                          if (!_loading && _devices.isEmpty)
                            Text(
                              'No registered devices yet.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          for (final device in _devices) ...[
                            DeviceRow(
                              title: device.name,
                              subtitle: 'ID: ${device.id}',
                              onTap: () => _openDeviceDetails(device),
                              onTrailingPressed: () =>
                                  _openDeviceDetails(device),
                              trailingIcon: Icons.more_vert,
                              borderColor: theme.dividerColor,
                              titleColor: theme.colorScheme.onSurface,
                              subtitleColor:
                                  theme.textTheme.bodyMedium?.color ??
                                  theme.colorScheme.onSurface,
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

