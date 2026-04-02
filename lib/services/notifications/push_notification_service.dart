import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../firebase_options.dart';
import '../api/notifications_api.dart';

const AndroidNotificationChannel _alertsChannel = AndroidNotificationChannel(
  'aerosaur-alerts',
  'Aerosaur Alerts',
  description:
      'Notifications for monitoring, device, system, and energy updates.',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class PushNotificationService {
  PushNotificationService(this._notificationsApi);

  final NotificationsApi _notificationsApi;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _storedTokenKey = 'push_notification_token';
  static const String _storedUserIdKey = 'push_notification_user_id';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _initializeLocalNotifications();
    await _requestPermissions();
    await _syncCurrentToken();

    FirebaseAuth.instance.authStateChanges().listen(_handleAuthStateChanged);
    FirebaseMessaging.instance.onTokenRefresh.listen(_handleTokenRefresh);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const settings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (_) {},
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(_alertsChannel);
  }

  Future<void> _requestPermissions() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> _handleAuthStateChanged(User? user) async {
    if (user == null) {
      await _unregisterStoredToken();
      return;
    }

    await _syncCurrentToken();
  }

  Future<void> _handleTokenRefresh(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _registerTokenForUser(user, token);
  }

  Future<void> _syncCurrentToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final token = await _messaging.getToken();
    if (token == null || token.isEmpty) return;

    await _registerTokenForUser(user, token);
  }

  Future<void> _registerTokenForUser(User user, String token) async {
    final packageInfo = await PackageInfo.fromPlatform();

    await _notificationsApi.registerPushToken(
      token: token,
      platform: defaultTargetPlatform.name,
      appVersion: packageInfo.version,
      deviceId: null,
    );

    await _secureStorage.write(key: _storedTokenKey, value: token);
    await _secureStorage.write(key: _storedUserIdKey, value: user.uid);
  }

  Future<void> _unregisterStoredToken() async {
    final token = await _secureStorage.read(key: _storedTokenKey);
    final userId = await _secureStorage.read(key: _storedUserIdKey);

    if (token != null &&
        token.isNotEmpty &&
        userId != null &&
        userId.isNotEmpty) {
      try {
        await _notificationsApi.unregisterPushToken(token);
      } catch (_) {
        // Keep sign out resilient even if token cleanup fails.
      }
    }

    await _secureStorage.delete(key: _storedTokenKey);
    await _secureStorage.delete(key: _storedUserIdKey);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _alertsChannel.id,
          _alertsChannel.name,
          channelDescription: _alertsChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }
}
