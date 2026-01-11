import 'package:flutter/material.dart';

enum NotificationType { warning, alert, info, smartMode, energy }

class NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final IconData icon;
  final bool isRead;
  final NotificationType type; // <-- new field

  const NotificationCard({
    super.key,
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
    required this.isRead,
    required this.type, // required
  });

  // Map notification type to color
  Color getIconColor(BuildContext context) {
    switch (type) {
      case NotificationType.warning:
        return Colors.amber; // yellow
      case NotificationType.alert:
        return Colors.red;
      case NotificationType.info:
        return Colors.blue;
      case NotificationType.smartMode:
        return Colors.green;
      case NotificationType.energy:
        return Colors.orange;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isRead
            ? Colors.transparent
            : theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: isRead
            ? Border.all(color: theme.dividerColor)
            : null, // outline for read
      ),
      child: Row(
        children: [
          // Icon with dynamic color
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: getIconColor(context).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: getIconColor(context), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(message, style: theme.textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
