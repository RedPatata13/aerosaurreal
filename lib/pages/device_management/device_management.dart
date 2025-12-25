import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/../models/device.dart';
import '/../components/topnavbar.dart';
import '/../enum/active_icon.dart';
import 'widgets/filled_input.dart';
import 'widgets/device_row.dart';
import 'widgets/dialog_button.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final titleMedium =
        theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);
    final bodyMedium =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);

    final pageBg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF5F6F7);
    final cardBg = isDark ? const Color(0xFF1F2228) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF2B2F36)
        : const Color(0xFFE5E7EB);
    final titleColor = isDark
        ? const Color(0xFFF3F4F6)
        : const Color(0xFF111827);
    final labelColor = isDark
        ? const Color(0xFFB9C0CB)
        : const Color(0xFF374151);
    final inputFill = isDark
        ? const Color(0xFF2B2F36)
        : const Color(0xFFD9D9D9);
    final danger = const Color(0xFFB42318);

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            children: [
              TopNavbar(
                iconColor: isDark ? Colors.white : const Color(0xFF111827),
                onBack: () => Navigator.pop(context),
                activeAdd: false,
                activeIcon: TopNavActiveIcon.none,
                onAdd: () {},
                onNotifications: () {},
                onSettings: () {
                  Navigator.pushNamed(context, 'settings.dart');
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Device Management',
                          style: titleMedium.copyWith(
                            color: titleColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Register new Device',
                          style: bodyMedium.copyWith(
                            color: labelColor,
                            fontWeight: FontWeight.w700,
                            fontSize: (bodyMedium.fontSize ?? 14) - 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: FilledInput(
                                controller: _deviceIdController,
                                fill: inputFill,
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
                                style: ElevatedButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  backgroundColor: isDark
                                      ? const Color(0xFF415A77)
                                      : const Color(0xFF1B263B),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
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
                          fill: inputFill,
                          hint: 'Enter Name Device',
                        ),
                        const SizedBox(height: 14),
                        Divider(color: borderColor, height: 1),
                        const SizedBox(height: 14),
                        Text(
                          'Registered Devices',
                          style: bodyMedium.copyWith(
                            color: labelColor,
                            fontWeight: FontWeight.w700,
                            fontSize: (bodyMedium.fontSize ?? 14) - 2,
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
                            danger: danger,
                            borderColor: borderColor,
                            titleColor: titleColor,
                            subtitleColor: isDark
                                ? const Color(0xFFB9C0CB)
                                : const Color(0xFF6B7280),
                            cardBg: cardBg,
                          ),
                          const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
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
    final isDark = theme.brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1F2228) : Colors.white;
    final borderColor = isDark
        ? const Color(0xFF2B2F36)
        : const Color(0xFFE5E7EB);
    final titleColor = isDark
        ? const Color(0xFFF3F4F6)
        : const Color(0xFF111827);
    final danger = const Color(0xFFB42318);

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
              color: dialogBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Are you sure you want to\nremove this device?',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: titleColor,
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
                        borderColor: borderColor,
                        foreground: titleColor,
                        background: null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: DialogButton(
                        label: 'Confirm',
                        onPressed: () => Navigator.of(context).pop(true),
                        primary: true,
                        borderColor: borderColor,
                        foreground: Colors.white,
                        background: danger,
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
