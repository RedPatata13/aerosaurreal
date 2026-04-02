import 'package:flutter/material.dart';

enum AppNotificationVisualType { warning, critical, info, system, energy }

class AppNotification {
  final String id;
  final String notificationId;
  final String title;
  final String body;
  final String category;
  final String type;
  final String severity;
  final bool isRead;
  final DateTime? createdAt;
  final String? deviceId;
  final String? deviceName;

  const AppNotification({
    required this.id,
    required this.notificationId,
    required this.title,
    required this.body,
    required this.category,
    required this.type,
    required this.severity,
    required this.isRead,
    required this.createdAt,
    this.deviceId,
    this.deviceName,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] ?? json['notificationId'] ?? '').toString(),
      notificationId: (json['notificationId'] ?? json['id'] ?? '').toString(),
      title: (json['title'] ?? 'Notification').toString(),
      body: (json['body'] ?? '').toString(),
      category: (json['category'] ?? 'system').toString(),
      type: (json['type'] ?? 'general').toString(),
      severity: (json['severity'] ?? 'info').toString(),
      isRead: json['isRead'] == true,
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      deviceId: json['deviceId']?.toString(),
      deviceName: json['deviceName']?.toString(),
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      notificationId: notificationId,
      title: title,
      body: body,
      category: category,
      type: type,
      severity: severity,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      deviceId: deviceId,
      deviceName: deviceName,
    );
  }

  AppNotificationVisualType get visualType {
    if (severity == 'critical' || severity == 'warning') {
      return AppNotificationVisualType.warning;
    }
    if (category == 'energy') return AppNotificationVisualType.energy;
    if (category == 'system' || type.contains('system')) {
      return AppNotificationVisualType.system;
    }
    if (severity == 'critical') return AppNotificationVisualType.critical;
    return AppNotificationVisualType.info;
  }

  IconData get icon {
    if (type.contains('gas') || type.contains('aqi')) {
      return Icons.warning_amber_rounded;
    }
    if (type.contains('offline')) {
      return Icons.wifi_off_rounded;
    }
    if (type.contains('online') || type.contains('connected')) {
      return Icons.devices_rounded;
    }
    if (category == 'energy') {
      return Icons.bolt_rounded;
    }
    if (category == 'smart_mode') {
      return Icons.auto_awesome_rounded;
    }
    if (category == 'system') {
      return Icons.system_update_alt_rounded;
    }
    return Icons.notifications_active_rounded;
  }
}
