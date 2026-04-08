import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_notification.dart';
import '../../models/device.dart';
import '../../models/notification_preferences.dart';
import '../../routes/routes.dart';
import '../../services/api/api_client.dart';
import '../../services/api/notifications_api.dart';
import '../../state/notifications_store.dart';
import '../device_management/device_management_args.dart';
import '../home/widgets/home_header.dart';
import 'widgets/notification_card.dart';
import 'widgets/toggle_section.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  late final NotificationsApi _notificationsApi;
  late final NotificationsStore _notificationsStore;

  NotificationPreferences _preferences = const NotificationPreferences(
    enabled: true,
    alerts: true,
    smartMode: true,
    energy: true,
  );
  List<AppNotification> _items = const [];
  List<Device> devicesState = [];
  int selectedDeviceIndex = 0;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notificationsApi = NotificationsApi(context.read<ApiClient>());
    _notificationsStore = context.read<NotificationsStore>();
    if (_loading && _items.isEmpty && _error == null) {
      _loadNotifications();
    }
  }

  @override
  void dispose() {
    final hasUnread = _items.any((item) => !item.isRead);
    if (hasUnread) {
      _notificationsStore.clearUnreadState();
      unawaited(
        _notificationsApi.markAllAsRead().catchError((_) {
          if (mounted) {
            _notificationsStore.refreshUnreadState(silent: true);
          }
        }),
      );
    }
    super.dispose();
  }

  Future<void> _openDeviceManagement(String uid) async {
    await Navigator.of(context).pushNamed(
      AppRoutes.deviceManagement,
      arguments: DeviceManagementArgs(
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

  Future<void> _loadNotifications() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _notificationsApi.fetchNotifications();
      if (!mounted) return;
      setState(() {
        _preferences = response.settings;
        _items = response.items;
      });
      _notificationsStore.applyReadState(
        response.items.map((item) => !item.isRead),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load notifications';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _updateSetting(String key, bool value) async {
    final previous = _preferences;

    final optimistic = switch (key) {
      'enabled' => _preferences.copyWith(enabled: value),
      'alerts' => _preferences.copyWith(alerts: value),
      'smartMode' => _preferences.copyWith(smartMode: value),
      'energy' => _preferences.copyWith(energy: value),
      _ => _preferences,
    };

    setState(() {
      _preferences = optimistic;
    });

    try {
      final updated = await _notificationsApi.updateSettings({key: value});
      if (!mounted) return;
      setState(() {
        _preferences = updated;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _preferences = previous;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update notification settings')),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    if (_busy || _items.isEmpty) return;

    setState(() {
      _busy = true;
      _items = _items
          .map((item) => item.copyWith(isRead: true))
          .toList(growable: false);
    });
    _notificationsStore.clearUnreadState();

    try {
      await _notificationsApi.markAllAsRead();
    } catch (e) {
      await _loadNotifications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to mark notifications as read')),
      );
      _notificationsStore.refreshUnreadState(silent: true);
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _clearAll() async {
    if (_busy || _items.isEmpty) return;

    setState(() {
      _busy = true;
      _items = const [];
    });

    try {
      await _notificationsApi.clearAll();
    } catch (e) {
      await _loadNotifications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to clear notifications')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _markItemAsRead(AppNotification item) async {
    if (item.isRead || _busy) return;

    setState(() {
      _items = _items
          .map(
            (entry) => entry.notificationId == item.notificationId
                ? entry.copyWith(isRead: true)
                : entry,
          )
          .toList(growable: false);
    });
    _notificationsStore.applyReadState(_items.map((entry) => !entry.isRead));

    try {
      await _notificationsApi.markAsRead(item.notificationId);
    } catch (e) {
      await _loadNotifications();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update notification')),
      );
      _notificationsStore.refreshUnreadState(silent: true);
    }
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
                _openDeviceManagement(uid);
              },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: RefreshIndicator(
                color: theme.colorScheme.primary,
                onRefresh: _loadNotifications,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [
                    NotificationToggleSection(
                      items: [
                        NotificationToggleItem(
                          label: 'Notifications',
                          value: _preferences.enabled,
                          onChanged: (value) =>
                              _updateSetting('enabled', value),
                        ),
                        if (_preferences.enabled) ...[
                          NotificationToggleItem(
                            label: 'Alerts',
                            value: _preferences.alerts,
                            onChanged: (value) =>
                                _updateSetting('alerts', value),
                          ),
                          NotificationToggleItem(
                            label: 'Smart Mode Changes',
                            value: _preferences.smartMode,
                            onChanged: (value) =>
                                _updateSetting('smartMode', value),
                          ),
                          NotificationToggleItem(
                            label: 'Energy Usage',
                            value: _preferences.energy,
                            onChanged: (value) =>
                                _updateSetting('energy', value),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildHistorySection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection() {
    if (!_preferences.enabled) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor, width: 1.2),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notification History',
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _ActionButton(
                label: 'Mark all as read',
                color: theme.colorScheme.primary,
                onPressed: _items.isEmpty ? null : _markAllAsRead,
              ),
              const SizedBox(width: 12),
              _ActionButton(
                label: 'Clear All',
                color: const Color(0xFFFF4B3A),
                onPressed: _items.isEmpty ? null : _clearAll,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_loading)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              ),
            )
          else if (_error != null)
            _HistoryMessage(
              message: _error!,
              actionLabel: 'Retry',
              onPressed: _loadNotifications,
            )
          else if (_items.isEmpty)
            const _HistoryMessage(message: 'No notifications yet')
          else
            Column(
              children: _items
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: NotificationCard(
                        item: item,
                        onTap: () => _markItemAsRead(item),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: color.withValues(alpha: 0.45),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;

  const _HistoryMessage({
    required this.message,
    this.actionLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
              fontSize: 14,
            ),
          ),
          if (actionLabel != null && onPressed != null) ...[
            const SizedBox(height: 12),
            TextButton(onPressed: onPressed, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
