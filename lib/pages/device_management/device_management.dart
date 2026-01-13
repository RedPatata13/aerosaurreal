import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '/../models/device.dart';
import '/../enum/active_icon.dart';
import 'widgets/filled_input.dart';
import 'widgets/device_row.dart';
import 'widgets/dialog_button.dart';
import './../home/widgets/home_header.dart';

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
  bool _saving = false;

  @override
  void dispose() {
    _deviceIdController.dispose();
    _deviceNameController.dispose();
    super.dispose();
  }

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
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            HomeHeader(
              username: username,
              iconColor: theme.colorScheme.onSurface,
              onRegisterDevice: () {
                if (uid == null) return;
                _showRegisterDeviceDialog(uid);
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: SingleChildScrollView(
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
                              (theme.textTheme.titleMedium ?? const TextStyle())
                                  .copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Register new Device',
                          style:
                              (theme.textTheme.bodyMedium ?? const TextStyle())
                                  .copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: FilledInput(
                                controller: _deviceIdController,
                                fill: theme.inputDecorationTheme.fillColor!,
                                hint: 'Enter Device ID (e.g 2024-AVXXXXXX)',
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: ElevatedButton(
                                onPressed: _saving
                                    ? null
                                    : () {
                                        final id = _deviceIdController.text
                                            .trim();
                                        if (id.isNotEmpty) {
                                          _submitNewDevice();
                                          return;
                                        }
                                        FocusScope.of(context).requestFocus();
                                      },
                                style: theme.elevatedButtonTheme.style
                                    ?.copyWith(
                                      padding: MaterialStateProperty.all(
                                        EdgeInsets.zero,
                                      ),
                                      shape: MaterialStateProperty.all(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                child: const Icon(Icons.add, size: 20),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        FilledInput(
                          controller: _deviceNameController,
                          fill: theme.inputDecorationTheme.fillColor!,
                          hint: 'Enter Name Device',
                        ),
                        const SizedBox(height: 14),
                        Divider(color: theme.dividerColor, height: 1),
                        const SizedBox(height: 14),
                        Text(
                          'Registered Devices',
                          style:
                              (theme.textTheme.bodyMedium ?? const TextStyle())
                                  .copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                        ),
                        const SizedBox(height: 10),
                        for (final device in widget.devices) ...[
                          DeviceRow(
                            title: device.name,
                            subtitle: 'ID: 2024-${device.id}',
                            onDelete: _saving
                                ? null
                                : () => _confirmDelete(device.id),
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
          ],
        ),
      ),
    );
  }

  Future<void> _submitNewDevice() async {
    final id = _deviceIdController.text.trim();
    final name = _deviceNameController.text.trim();
    if (id.isEmpty || _saving) return;
    setState(() => _saving = true);
    final effectiveName = name.isEmpty ? 'Device' : name;

    try {
      final newDevice = Device.demoFromDb(
        id: id,
        name: effectiveName,
        seed: widget.devices.length,
      );
      final updatedDevices = [...widget.devices, newDevice];
      widget.onDevicesChanged(updatedDevices);

      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'devices': FieldValue.arrayUnion([
          {'code': id, 'name': effectiveName, 'createdAt': Timestamp.now()},
        ]),
      }, SetOptions(merge: true));

      if (!mounted) return;
      _deviceIdController.clear();
      _deviceNameController.clear();
      setState(() => _saving = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to add device.')));
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
                  mainAxisAlignment: MainAxisAlignment.center,
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
      await _deleteDevice(deviceId);
    }
  }

  Future<void> _deleteDevice(String deviceId) async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final updatedDevices = widget.devices
          .where((d) => d.id != deviceId)
          .toList();
      widget.onDevicesChanged(updatedDevices);

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .get();
      final data = doc.data() ?? {};
      final raw = (data['devices'] as List?) ?? [];
      final filtered = raw.where((entry) {
        if (entry is Map) return entry['code']?.toString() != deviceId;
        if (entry is String) return entry != deviceId;
        return true;
      }).toList();

      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'devices': filtered,
      }, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => _saving = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to remove device.')));
    }
  }
}
