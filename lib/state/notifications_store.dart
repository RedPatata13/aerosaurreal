import 'package:flutter/foundation.dart';

import '../services/api/notifications_api.dart';
import '../services/notifications/push_notification_service.dart';

class NotificationsStore extends ChangeNotifier {
  NotificationsStore(this._notificationsApi, this._pushNotificationService) {
    _pushNotificationService.addForegroundRefreshListener(
      _handleForegroundPush,
    );
  }

  final NotificationsApi _notificationsApi;
  final PushNotificationService _pushNotificationService;

  bool _loading = false;
  int _unreadCount = 0;

  bool get isLoading => _loading;
  int get unreadCount => _unreadCount;
  bool get hasUnread => _unreadCount > 0;

  Future<void> refreshUnreadState({bool silent = false}) async {
    if (_loading) return;

    _loading = true;
    if (!silent) {
      notifyListeners();
    }

    try {
      final response = await _notificationsApi.fetchNotifications();
      _unreadCount = response.items.where((item) => !item.isRead).length;
    } catch (_) {
      // Keep the badge resilient if unread refresh fails.
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void applyReadState(Iterable<bool> unreadFlags) {
    _unreadCount = unreadFlags.where((isUnread) => isUnread).length;
    notifyListeners();
  }

  void clearUnreadState() {
    if (_unreadCount == 0) return;
    _unreadCount = 0;
    notifyListeners();
  }

  Future<void> markAllAsRead() async {
    final previousUnreadCount = _unreadCount;
    _unreadCount = 0;
    notifyListeners();

    try {
      await _notificationsApi.markAllAsRead();
    } catch (_) {
      _unreadCount = previousUnreadCount;
      notifyListeners();
      rethrow;
    }
  }

  void _handleForegroundPush() {
    refreshUnreadState(silent: true);
  }

  @override
  void dispose() {
    _pushNotificationService.removeForegroundRefreshListener(
      _handleForegroundPush,
    );
    super.dispose();
  }
}
