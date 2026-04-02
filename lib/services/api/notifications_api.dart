import '../../models/app_notification.dart';
import '../../models/notification_preferences.dart';
import 'api_client.dart';

class NotificationsResponse {
  final NotificationPreferences settings;
  final List<AppNotification> items;
  final int unreadCount;

  const NotificationsResponse({
    required this.settings,
    required this.items,
    required this.unreadCount,
  });
}

class NotificationsApi {
  final ApiClient _api;

  NotificationsApi(this._api);

  Future<NotificationsResponse> fetchNotifications() async {
    final res = await _api.getJson('/notifications');

    final rawSettings = res['settings'];
    final rawItems = res['items'];

    return NotificationsResponse(
      settings: rawSettings is Map<String, dynamic>
          ? NotificationPreferences.fromJson(rawSettings)
          : const NotificationPreferences(
              enabled: true,
              alerts: true,
              smartMode: true,
              energy: true,
            ),
      items: rawItems is List
          ? rawItems
                .whereType<Map>()
                .map(
                  (item) =>
                      AppNotification.fromJson(item.cast<String, dynamic>()),
                )
                .toList(growable: false)
          : const [],
      unreadCount: (res['unreadCount'] as num?)?.toInt() ?? 0,
    );
  }

  Future<NotificationPreferences> updateSettings(
    Map<String, dynamic> patch,
  ) async {
    final res = await _api.patchJson('/notifications/settings', body: patch);
    final raw = res['settings'];
    if (raw is Map<String, dynamic>) {
      return NotificationPreferences.fromJson(raw);
    }
    throw Exception('Unexpected notification settings response: $res');
  }

  Future<void> markAllAsRead() async {
    await _api.postJson('/notifications/mark-all-read', body: const {});
  }

  Future<void> markAsRead(String notificationId) async {
    await _api.postJson('/notifications/$notificationId/read', body: const {});
  }

  Future<void> clearAll() async {
    await _api.deleteJson('/notifications/clear-all');
  }

  Future<void> registerPushToken({
    required String token,
    required String platform,
    String? appVersion,
    String? deviceId,
  }) async {
    await _api.postJson(
      '/notifications/tokens',
      body: {
        'token': token,
        'platform': platform,
        if (appVersion != null && appVersion.isNotEmpty)
          'appVersion': appVersion,
        if (deviceId != null && deviceId.isNotEmpty) 'deviceId': deviceId,
      },
    );
  }

  Future<void> unregisterPushToken(String token) async {
    await _api.deleteJson('/notifications/tokens', body: {'token': token});
  }
}
