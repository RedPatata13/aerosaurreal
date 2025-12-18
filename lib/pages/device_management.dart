import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/device.dart';
import '../platform/system_settings.dart';

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
    final bodyMedium = theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);

    final pageBg = isDark ? const Color(0xFF0B1220) : const Color(0xFFF5F6F7);
    final cardBg = isDark ? const Color(0xFF1F2228) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2B2F36) : const Color(0xFFE5E7EB);
    final titleColor = isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827);
    final labelColor = isDark ? const Color(0xFFB9C0CB) : const Color(0xFF374151);
    final inputFill = isDark ? const Color(0xFF2B2F36) : const Color(0xFFD9D9D9);
    final danger = const Color(0xFFB42318);

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            children: [
              _TopBar(
                iconColor: isDark ? Colors.white : const Color(0xFF111827),
                onBack: () => Navigator.of(context).pop(),
                activeAdd: true,
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
                              child: _FilledInput(
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
                                        final id =
                                            _deviceIdController.text.trim();
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
                        _FilledInput(
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
                          _DeviceRow(
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
    if (id.isEmpty) return;
    final effectiveName = name.isEmpty ? 'Device' : name;
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final newDevice = Device.demoFromDb(
        id: id,
        name: effectiveName,
        seed: widget.devices.length,
      );
      final next = [...widget.devices, newDevice];
      widget.onDevicesChanged(next);

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add device.')),
      );
    }
  }

  Future<void> _confirmDelete(String deviceId) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1F2228) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2B2F36) : const Color(0xFFE5E7EB);
    final titleColor = isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827);
    final danger = const Color(0xFFB42318);

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            width: 340,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final buttonWidth = ((width - 14) / 2).clamp(110.0, 160.0);
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: buttonWidth,
                          child: _DialogButton(
                            label: 'Back',
                            onPressed: () => Navigator.of(context).pop(false),
                            primary: false,
                            borderColor: borderColor,
                            foreground: titleColor,
                            background: null,
                          ),
                        ),
                        const SizedBox(width: 14),
                        SizedBox(
                          width: buttonWidth,
                          child: _DialogButton(
                            label: 'Confirm',
                            onPressed: () => Navigator.of(context).pop(true),
                            primary: true,
                            borderColor: borderColor,
                            foreground: Colors.white,
                            background: danger,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (shouldDelete != true) return;
    await _deleteDevice(deviceId);
  }

  Future<void> _deleteDevice(String deviceId) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final next = widget.devices.where((d) => d.id != deviceId).toList();
      widget.onDevicesChanged(next);

      final doc =
          await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      final data = doc.data() ?? const <String, dynamic>{};
      final raw = (data['devices'] as List?) ?? const [];
      final filtered = raw.where((entry) {
        if (entry is Map) {
          return entry['code']?.toString() != deviceId;
        }
        if (entry is String) return entry != deviceId;
        return true;
      }).toList(growable: false);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.uid)
          .set({'devices': filtered}, SetOptions(merge: true));

      if (!mounted) return;
      setState(() => _saving = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to remove device.')),
      );
    }
  }
}

class _TopBar extends StatelessWidget {
  final Color iconColor;
  final VoidCallback onBack;
  final bool activeAdd;

  const _TopBar({
    required this.iconColor,
    required this.onBack,
    required this.activeAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: Icon(Icons.arrow_back, color: iconColor),
          iconSize: 22,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        ),
        const Spacer(),
        _TopIconButton(
          onPressed: () async {
            try {
              await SystemSettings.openWifiSettings();
            } catch (_) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Unable to open Wi‑Fi settings.')),
              );
            }
          },
          icon: Icons.wifi,
          tooltip: 'Wi‑Fi',
          color: iconColor,
        ),
        const SizedBox(width: 4),
        _TopIconButton(
          onPressed: null,
          icon: Icons.add,
          tooltip: 'Add device',
          color: iconColor,
          active: activeAdd,
        ),
        const SizedBox(width: 4),
        _TopIconButton(
          onPressed: () {},
          icon: Icons.notifications_none,
          tooltip: 'Notifications',
          color: iconColor,
        ),
        const SizedBox(width: 4),
        _TopIconButton(
          onPressed: () {},
          icon: Icons.settings_outlined,
          tooltip: 'Settings',
          color: iconColor,
        ),
      ],
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String tooltip;
  final Color color;
  final bool active;

  const _TopIconButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    required this.color,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = active ? null : onPressed;
    final effectiveColor =
        active ? color.withValues(alpha: 0.45) : color.withValues(alpha: 1);

    return IconButton(
      onPressed: effectiveOnPressed,
      tooltip: tooltip,
      iconSize: 20,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      icon: Icon(icon, color: effectiveColor),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final Color borderColor;
  final Color foreground;
  final Color? background;

  const _DialogButton({
    required this.label,
    required this.onPressed,
    required this.primary,
    required this.borderColor,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonChild = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (primary) {
      return SizedBox(
        height: 42,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) - 1,
            ),
          ),
          child: buttonChild,
        ),
      );
    }

    return SizedBox(
      height: 42,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor),
          foregroundColor: foreground,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) - 1,
          ),
        ),
        child: buttonChild,
      ),
    );
  }
}

class _FilledInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color fill;

  const _FilledInput({
    required this.controller,
    required this.hint,
    required this.fill,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFF3F4F6) : const Color(0xFF111827);
    final hintColor = isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
    final baseFontSize = theme.textTheme.bodyMedium?.fontSize ?? 14;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      child: TextSelectionTheme(
        data: const TextSelectionThemeData(selectionColor: Colors.transparent),
        child: TextField(
          controller: controller,
          cursorColor: textColor,
          textAlignVertical: TextAlignVertical.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: baseFontSize + 1,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            filled: true,
            fillColor: fill,
            contentPadding: EdgeInsets.zero,
            hintText: hint,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: hintColor,
              fontWeight: FontWeight.w600,
              fontSize: baseFontSize,
            ),
          ),
        ),
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onDelete;
  final Color danger;
  final Color borderColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color cardBg;

  const _DeviceRow({
    required this.title,
    required this.subtitle,
    required this.onDelete,
    required this.danger,
    required this.borderColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: subtitleColor,
                    fontWeight: FontWeight.w600,
                    fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12) - 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              onPressed: onDelete,
              icon: Icon(Icons.delete, color: danger, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            ),
          ),
        ],
      ),
    );
  }
}
