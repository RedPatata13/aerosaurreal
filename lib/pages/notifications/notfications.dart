import 'package:flutter/material.dart';
import 'widgets/toggle_section.dart';
import 'widgets/notification_card.dart';
import '/../components/topnavbar.dart'; // import your TopNavbar
import '/../enum/active_icon.dart';
import '/../routes/routes.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  // Toggle states
  bool notifications = true;
  bool alerts = false;
  bool smartModeChanges = true;
  bool energyUsage = false;

  // Sample notification items with read status
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // ---- Top Navbar ----
              TopNavbar(
                iconColor: theme.brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black,
                onBack: () => Navigator.of(context).pop(),
                activeAdd: false,
                onAdd: () {}, // optional add action
                onNotifications: () {},
                onSettings: () =>
                    Navigator.of(context).pushNamed(AppRoutes.settings),
                onWifi: () {},
                activeIcon: TopNavActiveIcon.notifications,
              ),

              const SizedBox(height: 20),

              // ---- Notification Toggles ----
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
                      onChanged: (v) => setState(() => smartModeChanges = v),
                    ),
                    NotificationToggleItem(
                      label: "Energy Usage",
                      value: energyUsage,
                      onChanged: (v) => setState(() => energyUsage = v),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 20),

              // ---- Notification History ----
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
                        // Header
                        const Text(
                          'Notification History',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Buttons below header
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
                                backgroundColor:
                                    theme.primaryColor, // Accent color
                                foregroundColor: Colors.white, // Text color
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              child: const Text('Mark all as read'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () {
                                setState(() => notificationItems.clear());
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                textStyle: const TextStyle(fontSize: 12),
                              ),
                              child: const Text('Clear All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Notification list
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
                                      type: item['type'], // pass type
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
    );
  }
}
