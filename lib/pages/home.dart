import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'dashboard.dart';
import 'monitoring.dart';
import 'insights.dart';
import 'device_management.dart';
import '../models/device.dart';
import '../platform/system_settings.dart';
import '../components/navbar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Use a nullable Future to handle the case where the user might log out
  // immediately or the Future can't be initialized (though less likely here).
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

    // Check 1: Ensure the user is authenticated before proceeding.
    if (currentUser == null) {
      print('Current user is not authenticated. Redirecting to login.');
      _handleLogoutAndRedirect();
      return;
    }

    final uid = currentUser.uid;

    _userDocStream = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots();
  }

  // Refactored logout function to handle the sign out and navigation safely.
  void _handleLogoutAndRedirect() async {
    // 1. Log out the user
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn.instance.disconnect();
    // if(GoogleSignIn.instance.currentUser != null)
    // await GoogleSignIn.instance.signOut();
    // 2. Safely redirect to /login
    // Must check if the widget is still mounted before navigating.
    if (!mounted) return;

    // Use pushReplacementNamed to prevent the user from navigating back
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _showRegisterDeviceDialog(String uid) {
    showDialog<void>(
      context: context,
      builder: (context) => _RegisterDeviceDialog(uid: uid),
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
          // Immediately log out the user and redirect if there's an error fetching data
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleLogoutAndRedirect();
          });

          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
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
                padding: EdgeInsets.all(32.0),
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
          body: SafeArea(
            child: Column(
              children: [
                _HomeHeader(
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
                      : _NoDeviceContent(
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

class _HomeHeader extends StatelessWidget {
  final String username;
  final Color iconColor;
  final VoidCallback onRegisterDevice;

  const _HomeHeader({
    required this.username,
    required this.iconColor,
    required this.onRegisterDevice,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const navy = Color(0xFF1B263B);
    const slate = Color(0xFF415A77);
    final titleColor = isDark
        ? const Color(0xFFF3F4F6)
        : const Color(0xFF111827);
    final bodySmall =
        theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
    final titleMedium =
        theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 26, 18, 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: isDark
                ? slate.withValues(alpha: 0.75)
                : const Color(0xFFF2F4F7),
            child: Icon(
              Icons.person_outline,
              color: isDark ? Colors.white : navy,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello!',
                  style: bodySmall.copyWith(
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                ),
                Text(
                  username,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: (titleMedium.fontSize ?? 16) + 2,
                    color: titleColor,
                  ),
                ),
              ],
            ),
          ),
          _TopIconButton(
            onPressed: () async {
              try {
                await SystemSettings.openWifiSettings();
              } catch (_) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Unable to open Wi‑Fi settings.'),
                  ),
                );
              }
            },
            icon: Icons.wifi,
            tooltip: 'Wi‑Fi',
            color: iconColor,
          ),
          const SizedBox(width: 4),
          _TopIconButton(
            onPressed: onRegisterDevice,
            icon: Icons.add,
            tooltip: 'Register device',
            color: iconColor,
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
      ),
    );
  }
}

class _NoDeviceContent extends StatelessWidget {
  final VoidCallback onRegisterDevice;
  final VoidCallback onLogout;

  const _NoDeviceContent({
    required this.onRegisterDevice,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const navy = Color(0xFF1B263B);
    const slate = Color(0xFF415A77);
    const danger = Color(0xFFC53A3A);
    final cardBg = isDark ? const Color(0xFF1F2228) : Colors.white;
    final cardBorder = isDark
        ? const Color(0xFF2B2F36)
        : const Color(0xFFD1D5DB);
    final titleColor = isDark
        ? const Color(0xFFF3F4F6)
        : const Color(0xFF111827);
    final bodyColor = isDark
        ? const Color(0xFFB9C0CB)
        : const Color(0xFF4B5563);
    final primaryButton = isDark ? slate : navy;
    final bodyMedium =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
    final titleMedium =
        theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder, width: 1.2),
              boxShadow: isDark
                  ? const []
                  : const [
                      BoxShadow(
                        color: Color(0x11000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 34, 18, 28),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'No devices registered on your account.',
                    textAlign: TextAlign.center,
                    style: titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "It appears you don't have any devices registered. Register your device now!",
                    textAlign: TextAlign.center,
                    style: bodyMedium.copyWith(color: bodyColor, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 330),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: onRegisterDevice,
                        icon: const Icon(Icons.link, size: 18),
                        label: const Text('Register new device'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryButton,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          textStyle: bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: (bodyMedium.fontSize ?? 14) - 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 40,
                    width: 120,
                    child: ElevatedButton.icon(
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        textStyle: bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: (bodyMedium.fontSize ?? 14) - 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;
  final Color color;
  final bool active;

  const _TopIconButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.color = const Color(0xFF111827),
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = active
        ? color.withValues(alpha: 0.45)
        : color.withValues(alpha: 1);
    return IconButton(
      onPressed: active ? null : onPressed,
      tooltip: tooltip,
      iconSize: 20,
      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 34, height: 34),
      icon: Icon(icon, color: effectiveColor),
    );
  }
}

class _RegisterDeviceDialog extends StatefulWidget {
  final String uid;

  const _RegisterDeviceDialog({required this.uid});

  @override
  State<_RegisterDeviceDialog> createState() => _RegisterDeviceDialogState();
}

class _RegisterDeviceDialogState extends State<_RegisterDeviceDialog> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      _controllers[index].text = value.substring(value.length - 1);
      _controllers[index].selection = const TextSelection.collapsed(offset: 1);
    }

    if (value.isNotEmpty && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    setState(() {});
  }

  void _onBackspace(int index) {
    if (index > 0 && _controllers[index].text.isEmpty) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      setState(() {});
    }
  }

  void _submit() {
    Navigator.of(context).pop();
    showDialog<void>(
      context: context,
      builder: (context) => _DeviceRegisteredDialog(
        uid: widget.uid,
        code: _controllers.map((c) => c.text).join(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final isComplete = _controllers.every(
      (controller) => controller.text.isNotEmpty,
    );
    final dialogBg = isDark ? const Color(0xFF1F2228) : Colors.white;
    final dialogText = isDark
        ? const Color(0xFFB9C0CB)
        : const Color(0xFF374151);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SizedBox(
          width: 340,
          height: 380,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: dialogBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 8.0;
                  final available = constraints.maxWidth - (gap * 5);
                  final rawWidth = available / 6;
                  final boxWidth = rawWidth.clamp(34.0, 46.0);

                  return Column(
                    children: [
                      Row(
                        children: [
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close,
                              color: isDark ? Colors.white : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        Icons.smartphone,
                        size: 82,
                        color: isDark
                            ? const Color(0xFF415A77)
                            : colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Enter the code shown on your device to add it to your account',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: dialogText,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (index) {
                          return Row(
                            children: [
                              SizedBox(
                                width: boxWidth,
                                height: 44,
                                child: Focus(
                                  onKeyEvent: (node, event) {
                                    if (event is KeyDownEvent &&
                                        event.logicalKey ==
                                            LogicalKeyboardKey.backspace) {
                                      _onBackspace(index);
                                    }
                                    return KeyEventResult.ignored;
                                  },
                                  child: _CodeBox(
                                    controller: _controllers[index],
                                    focusNode: _focusNodes[index],
                                    onChanged: (value) =>
                                        _onChanged(index, value),
                                    onSubmitted: (_) {
                                      if (index == 5 && isComplete) _submit();
                                    },
                                  ),
                                ),
                              ),
                              if (index != 5) const SizedBox(width: gap),
                            ],
                          );
                        }),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: isComplete ? _submit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? const Color(0xFF415A77)
                                : colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            disabledBackgroundColor: isDark
                                ? const Color(0xFF2D3138)
                                : theme.disabledColor.withValues(alpha: 0.2),
                          ),
                          child: const Text('Register Device'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CodeBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const _CodeBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  State<_CodeBox> createState() => _CodeBoxState();
}

class _CodeBoxState extends State<_CodeBox> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const navy = Color(0xFF1B263B);
    final fill = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD9D9D9);
    final border = isDark ? const Color(0xFF4A4A4A) : const Color(0xFFC8C8C8);
    final titleMedium =
        theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);
    final codeStyle = titleMedium.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: (titleMedium.fontSize ?? 16) - 2,
      color: isDark ? const Color(0xFFF3F4F6) : navy,
    );

    return Container(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      alignment: Alignment.center,
      child: TextSelectionTheme(
        data: TextSelectionThemeData(
          selectionColor: Colors.transparent,
          selectionHandleColor: isDark ? Colors.white : navy,
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          cursorColor: isDark ? Colors.white : navy,
          style: codeStyle,
          inputFormatters: [
            LengthLimitingTextInputFormatter(1),
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            UpperCaseTextFormatter(),
          ],
          decoration: InputDecoration(
            filled: true,
            fillColor: fill,
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

class _DeviceRegisteredDialog extends StatefulWidget {
  final String uid;
  final String code;

  const _DeviceRegisteredDialog({required this.uid, required this.code});

  @override
  State<_DeviceRegisteredDialog> createState() =>
      _DeviceRegisteredDialogState();
}

class _DeviceRegisteredDialogState extends State<_DeviceRegisteredDialog> {
  final _nameController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveAndClose() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final deviceName = _nameController.text.trim();
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'devices': FieldValue.arrayUnion([
          {
            'code': widget.code,
            'name': deviceName,
            'createdAt': Timestamp.now(),
          },
        ]),
      }, SetOptions(merge: true));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add device: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const navy = Color(0xFF1B263B);
    final bodyMedium =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
    final dialogBg = isDark ? const Color(0xFF1F2228) : Colors.white;
    final titleColor = isDark
        ? const Color(0xFFF3F4F6)
        : const Color(0xFF111827);
    final inputFill = isDark
        ? const Color(0xFF3A3A3A)
        : const Color(0xFFD9D9D9);
    final inputBorder = isDark
        ? const Color(0xFF4A4A4A)
        : const Color(0xFFC8C8C8);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SizedBox(
          width: 340,
          height: 380,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: dialogBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          color: isDark ? Colors.white : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFF2E7D32),
                    child: Icon(Icons.check, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Account Registered\nSuccessfully!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: inputFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: inputBorder),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextSelectionTheme(
                      data: TextSelectionThemeData(
                        selectionColor: Colors.transparent,
                        selectionHandleColor: isDark ? Colors.white : navy,
                      ),
                      child: TextField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        cursorColor: isDark ? Colors.white : navy,
                        style: bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: (bodyMedium.fontSize ?? 14) - 1,
                          color: isDark ? const Color(0xFFF3F4F6) : navy,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: inputFill,
                          border: InputBorder.none,
                          isDense: true,
                          hintText: 'Add Device Name (Optional)',
                          hintStyle: bodyMedium.copyWith(
                            color: const Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w600,
                            fontSize: (bodyMedium.fontSize ?? 14) - 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveAndClose,
                      style: isDark
                          ? ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF415A77),
                              foregroundColor: Colors.white,
                            )
                          : null,
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Return to Account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
