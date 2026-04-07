import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/wifi_password_dialog.dart';
import '../../models/device.dart';
import '../../services/api/api_client.dart';
import '../../services/api/devices_api.dart';
import '../../services/api/readings_api.dart';
import '../../services/device/device_setup_service.dart';

class DeviceDetailsPage extends StatefulWidget {
  const DeviceDetailsPage({super.key, required this.device});

  final Device device;

  @override
  State<DeviceDetailsPage> createState() => _DeviceDetailsPageState();
}

class _DeviceDetailsPageState extends State<DeviceDetailsPage> {
  static const Duration _onlineThreshold = Duration(minutes: 2);

  late final DevicesApi _devicesApi;
  late final ReadingsApi _readingsApi;
  late final DeviceSetupService _setupService;
  late Device _device;
  int? _lastReadingUpdatedAtSec;
  bool _servicesInitialized = false;
  bool _savingName = false;
  bool _removing = false;
  bool _provisioningWifi = false;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _device = widget.device;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_servicesInitialized) return;
    _servicesInitialized = true;

    final apiClient = context.read<ApiClient>();
    _devicesApi = DevicesApi(apiClient);
    _readingsApi = ReadingsApi(apiClient);
    _setupService = DeviceSetupService(_devicesApi);
    _refreshDeviceDetails(silent: true);
  }

  String get _deviceNameLabel {
    final trimmed = _device.name.trim();
    if (trimmed.isEmpty || trimmed == _device.id) {
      return 'Set name';
    }
    return trimmed;
  }

  String get _wifiStatusLabel {
    if (_device.isWifiConnected == true) {
      final wifiName = _device.wifiName?.trim();
      return wifiName == null || wifiName.isEmpty
          ? 'Connected'
          : 'Connected to $wifiName';
    }
    if (_device.isWifiConnected == false) {
      return 'Not connected';
    }

    final deviceWifiName = _device.wifiName?.trim();
    if (deviceWifiName != null && deviceWifiName.isNotEmpty) {
      return deviceWifiName;
    }

    return 'Unknown';
  }

  String get _onlineStatusLabel {
    final isOnline = _resolvedOnlineStatus;
    if (isOnline == true) return 'Online';
    if (isOnline == false) return 'Offline';
    return 'Unknown';
  }

  Color _statusColor(BuildContext context) {
    final isOnline = _resolvedOnlineStatus;
    if (isOnline == true) return const Color(0xFF2E7D32);
    if (isOnline == false) return const Color(0xFFC62828);
    return Theme.of(context).disabledColor;
  }

  bool? get _resolvedOnlineStatus {
    final updatedAtSec = _lastReadingUpdatedAtSec;
    if (updatedAtSec != null) {
      final lastSeen = DateTime.fromMillisecondsSinceEpoch(
        updatedAtSec * 1000,
        isUtc: true,
      ).toLocal();
      return DateTime.now().difference(lastSeen) <= _onlineThreshold;
    }

    return _device.isOnline;
  }

  Future<void> _refreshDeviceDetails({bool silent = false}) async {
    if (_refreshing) return;

    if (mounted) {
      setState(() => _refreshing = true);
    }

    try {
      final devices = await _devicesApi.listDevices();
      final matching = devices.cast<Map<String, dynamic>?>().firstWhere(
        (item) {
          final device = item;
          if (device == null) return false;
          final id = (device['deviceId'] ?? device['DeviceId'] ?? device['id'])
              ?.toString();
          return id == _device.id;
        },
        orElse: () => null,
      );

      if (matching != null && mounted) {
        final parsed = Device.fromApi(matching);
        setState(() {
          _device = _device.copyWith(
            name: parsed.name,
            wifiName: parsed.wifiName,
            isWifiConnected: parsed.isWifiConnected,
            isOnline: parsed.isOnline,
          );
        });
      }

      try {
        final latest = await _readingsApi.getLatest(_device.id);
        final updatedAtSec = (latest['updatedAtSec'] as num?)?.toInt();
        if (mounted) {
          setState(() {
            _lastReadingUpdatedAtSec = updatedAtSec;
          });
        }
      } catch (_) {
        // Keep the last known device data if latest readings are unavailable.
      }

    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to refresh device: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  Future<void> _editName() async {
    if (_savingName || _removing) return;

    final controller = TextEditingController(
      text: _device.name == _device.id ? '' : _device.name,
    );
    final focusNode = FocusNode();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF1F2228) : Colors.white;
    final dialogText = isDark
        ? const Color(0xFFB9C0CB)
        : const Color(0xFF374151);
    var nextName = controller.text.trim();

    void closeDialog(BuildContext dialogContext, bool submitted) {
      focusNode.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(dialogContext).pop(submitted);
      });
    }

    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isButtonEnabled = controller.text.trim().isNotEmpty;

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: SizedBox(
                  width: 340,
                  height: 360,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: dialogBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Spacer(),
                              IconButton(
                                onPressed: () =>
                                    closeDialog(dialogContext, false),
                                iconSize: 20,
                                icon: Icon(
                                  Icons.close,
                                  color: isDark ? Colors.white : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Edit Device Name',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.textTheme.headlineMedium?.color,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Set a name for this device.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: dialogText,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 28),
                          TextField(
                            controller: controller,
                            focusNode: focusNode,
                            autofocus: true,
                            onChanged: (value) {
                              nextName = value.trim();
                              setDialogState(() {});
                            },
                            decoration: const InputDecoration(
                              hintText: 'Device Name',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: 120,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: isButtonEnabled
                                  ? () => closeDialog(dialogContext, true)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isButtonEnabled
                                    ? (isDark
                                          ? const Color(0xFF415A77)
                                          : theme.colorScheme.primary)
                                    : (isDark
                                          ? Colors.grey.shade700
                                          : Colors.grey.shade300),
                                foregroundColor: isButtonEnabled
                                    ? theme.colorScheme.onPrimary
                                    : (isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade500),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Save'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (submitted != true || nextName.isEmpty) {
      focusNode.dispose();
      controller.dispose();
      return;
    }

    setState(() => _savingName = true);

    try {
      final updated = await _devicesApi.updateDeviceName(
        deviceId: _device.id,
        name: nextName,
      );

      if (!mounted) return;
      setState(() {
        _device = Device.fromApi(updated).copyWith(
          wifiName: _device.wifiName,
          isWifiConnected: _device.isWifiConnected,
          isOnline: _device.isOnline,
        );
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Device name updated.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update device name: $e')),
      );
    } finally {
      focusNode.dispose();
      controller.dispose();
      if (mounted) {
        setState(() => _savingName = false);
      }
    }
  }

  Future<void> _removeDevice() async {
    if (_removing) return;

    final theme = Theme.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Container(
            width: 340,
            height: 210,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
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
                const SizedBox(height: 10),
                Text(
                  'This will remove it from your app and ask the device to clear its Wi-Fi credentials and return to offline fallback mode.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurface,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Confirm'),
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

    if (shouldDelete != true) return;

    setState(() => _removing = true);

    try {
      await _devicesApi.unregisterDevice(_device.id);
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        const SnackBar(
          content: Text(
            'Device removed. The device will clear Wi-Fi credentials when it receives the removal command.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to unregister: $e')));
    } finally {
      if (mounted) {
        setState(() => _removing = false);
      }
    }
  }

  Future<void> _manageWifi() async {
    if (_provisioningWifi || _removing || _savingName) {
      return;
    }

    final wifiName = await _setupService.getSuggestedWifiName();
    if (wifiName == null || wifiName.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connect your phone to Wi-Fi first.')),
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

    if (result == null || result.password.isEmpty) return;

    setState(() => _provisioningWifi = true);

    try {
      await _setupService.provisionWifi(
        rawCode: _device.id,
        ssid: wifiName,
        pass: result.password,
      );

      if (!mounted) return;
      setState(() {
        _device = _device.copyWith(wifiName: wifiName, isWifiConnected: true);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Provision sent! Device will reboot and connect.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Provision failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _provisioningWifi = false);
      }
    }
  }

  Widget _infoTile({
    required BuildContext context,
    required String label,
    required String value,
    Widget? trailing,
    VoidCallback? onTap,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: valueColor ?? theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 10), trailing],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      iconSize: 20,
                      alignment: Alignment.centerLeft,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 24,
                        height: 30,
                      ),
                    ),
                  ),
                  Text(
                    'Device Information',
                    style: (theme.textTheme.titleMedium ?? const TextStyle())
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshDeviceDetails,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height * 0.65,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoTile(
                          context: context,
                          label: 'ID / Code',
                          value: _device.id,
                        ),
                        const SizedBox(height: 10),
                        _infoTile(
                          context: context,
                          label: 'Name',
                          value: _deviceNameLabel,
                          onTap: _editName,
                          trailing: _savingName
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  Icons.edit_outlined,
                                  color: theme.colorScheme.onSurface,
                                  size: 20,
                                ),
                        ),
                        const SizedBox(height: 10),
                        _infoTile(
                          context: context,
                          label: 'Wi-Fi',
                          value: _wifiStatusLabel,
                          onTap: _manageWifi,
                          trailing: _provisioningWifi
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  Icons.chevron_right,
                                  color: theme.colorScheme.onSurface,
                                  size: 20,
                                ),
                        ),
                        const SizedBox(height: 10),
                        _infoTile(
                          context: context,
                          label: 'Status',
                          value: _onlineStatusLabel,
                          trailing: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _statusColor(context),
                              shape: BoxShape.circle,
                            ),
                          ),
                          valueColor: _statusColor(context),
                        ),
                        const SizedBox(height: 18),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _removing ? null : _removeDevice,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _removing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Remove Device'),
                          ),
                        ),
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
}
