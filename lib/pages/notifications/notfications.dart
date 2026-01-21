import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../models/device.dart';
import './../home/widgets/home_header.dart';
import './../device_management/device_management.dart';
import 'widgets/toggle_section.dart';
import 'widgets/notification_card.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  bool notifications = true;
  bool alerts = false;
  bool smartModeChanges = true;
  bool energyUsage = false;

  List<Map<String, dynamic>> notificationItems = [
    {
      "title": "Device Alert",
      "message": "Temperature exceeded safe limits",
      "time": "2h ago",
      "icon": Icons.warning_amber_outlined,
      "isRead": false,
      "type": NotificationType.warning,
    },
    {
      "title": "Device Connected",
      "message": "Aerosaur Sensor #3 online",
      "time": "5h ago",
      "icon": Icons.devices,
      "isRead": false,
      "type": NotificationType.info,
    },
    {
      "title": "System Update",
      "message": "Firmware updated successfully",
      "time": "1d ago",
      "icon": Icons.update,
      "isRead": true,
      "type": NotificationType.smartMode,
    },
    {
      "title": "Energy Report",
      "message": "Daily consumption is high",
      "time": "1d ago",
      "icon": Icons.bolt,
      "isRead": false,
      "type": NotificationType.energy,
    },
  ];

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

  Future<void> _refreshNotifications() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      // re-fecth notifs
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.displayName ?? 'User';
    final uid = user?.uid;

    return Scaffold(
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
            const SizedBox(height: 16),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshNotifications,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      NotificationToggleSection(
                        items: [
                          NotificationToggleItem(
                            label: "Notifications",
                            value: notifications,
                            onChanged: (v) => setState(() => notifications = v),
                          ),
                          if (notifications) ...[
                            NotificationToggleItem(
                              label: "Alerts",
                              value: alerts,
                              onChanged: (v) => setState(() => alerts = v),
                            ),
                            NotificationToggleItem(
                              label: "Smart Mode Changes",
                              value: smartModeChanges,
                              onChanged: (v) =>
                                  setState(() => smartModeChanges = v),
                            ),
                            NotificationToggleItem(
                              label: "Energy Usage",
                              value: energyUsage,
                              onChanged: (v) => setState(() => energyUsage = v),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 12),

                      if (notifications)
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: theme.dividerColor),
                          ),
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Notification History',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                Row(
                                  children: [
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          for (var item in notificationItems) {
                                            item['isRead'] = true;
                                          }
                                        });
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 12,
                                        ),
                                      ),
                                      child: const Text('Mark all as read'),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton(
                                      onPressed: () {
                                        setState(
                                          () => notificationItems.clear(),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        textStyle: const TextStyle(
                                          fontSize: 12,
                                        ),
                                      ),
                                      child: const Text('Clear All'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

                                if (notificationItems.isEmpty)
                                  Center(
                                    child: Text(
                                      "No notifications",
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  )
                                else
                                  Column(
                                    children: notificationItems
                                        .map(
                                          (item) => Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 6.0,
                                            ),
                                            child: NotificationCard(
                                              title: item['title'],
                                              message: item['message'],
                                              time: item['time'],
                                              icon: item['icon'],
                                              isRead: item['isRead'] ?? false,
                                              type: item['type'],
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
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
