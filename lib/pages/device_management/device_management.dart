import 'package:aerosaur_2nd_sem/routes/routes.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '/../models/device.dart';
import '/../services/api/devices_api.dart';
import 'widgets/filled_input.dart';
import 'widgets/device_row.dart';
import './../home/widgets/home_header.dart';
import 'widgets/dialog_button.dart';
import '../../services/ble/ble_provisioning_service.dart';
import 'package:provider/provider.dart';
import '/services/api/api_client.dart';

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

  late final DevicesApi _api;

  bool _saving = false;
  bool _loading = true;
  String? _error;

  List<Device> _devices = [];

  @override
  void initState() {
    super.initState();
    _api = DevicesApi(context.read<ApiClient>());
    _devices = widget.devices;
    _loadDevices();
  }

  @override
  void dispose() {
    _deviceIdController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

  Future<void> _loadDevices() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final items = await _api.listDevices();
      final next = items.map(Device.fromApi).toList();

      if (!mounted) return;
      setState(() {
        _devices = next;
        _loading = false;
      });

      widget.onDevicesChanged(next);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _refreshDevices() => _loadDevices();

  Future<void> _submitNewDevice() async {
    final id = _deviceIdController.text.trim();
    final name = _deviceNameController.text.trim();

    if (id.isEmpty || _saving) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Device ID is required.')));
      return;
    }

    setState(() => _saving = true);

    try {
      await _api.registerDevice(deviceId: id, name: name.isEmpty ? null : name);
      await _loadDevices();

      if (!mounted) return;
      setState(() => _saving = false);

      _deviceIdController.clear();
      _deviceNameController.clear();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add device: $e')));
    }
  }

  Future<void> _showProvisionDialog(String deviceId) async {
    final ssidCtrl = TextEditingController();
    final passCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Provision Wi-Fi"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ssidCtrl,
              decoration: const InputDecoration(hintText: "Wi-Fi SSID"),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(hintText: "Wi-Fi Password"),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Provision"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final ssid = ssidCtrl.text.trim();
    final pass = passCtrl.text;

    if (ssid.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("SSID is required")));
      return;
    }

    try {
      await BleProvisioningService.provisionWifi(
        deviceId: deviceId,
        ssid: ssid,
        pass: pass,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Provision sent! Device will reboot and connect."),
        ),
      );

      await Future.delayed(const Duration(seconds: 3));
      await _loadDevices();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Provision failed: $e")));
    }
  }

  Future<void> _unregisterDevice(String deviceId) async {
    try {
      await _api.unregisterDevice(deviceId);
      await _loadDevices();
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Device unregistered.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to unregister: $e')));
    }
  }

  Future<void> _confirmDelete(String deviceId) async {
    final theme = Theme.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Are you sure you want to\nremove this device?',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: DialogButton(
                        label: 'Back',
                        onPressed: () => Navigator.of(context).pop(false),
                        primary: false,
                        borderColor: theme.dividerColor,
                        foreground: theme.colorScheme.onSurface,
                        background: null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: DialogButton(
                        label: 'Confirm',
                        onPressed: () => Navigator.of(context).pop(true),
                        primary: true,
                        borderColor: theme.dividerColor,
                        foreground: Colors.white,
                        background: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (shouldDelete == true) {
      await _unregisterDevice(deviceId);
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
              onRegisterDevice: () {
                Navigator.of(context).pushNamed(AppRoutes.deviceManagement);
              },
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
                            hint: 'Enter Device ID (e.g. 2024-AVXXXXXX)',
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
                            height: 42,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _submitNewDevice,
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
                              onDelete: () => _confirmDelete(device.id),
                              onTap: () => _showProvisionDialog(device.id),
                              danger: Colors.red,
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
