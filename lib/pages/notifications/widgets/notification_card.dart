import 'package:flutter/material.dart';
import '../../../models/app_notification.dart';

class NotificationCard extends StatelessWidget {
  final AppNotification item;
  final VoidCallback? onTap;

  const NotificationCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = _paletteFor(item.visualType);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: item.isRead
                ? Colors.transparent
                : theme.colorScheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: item.isRead
                  ? theme.dividerColor
                  : theme.colorScheme.primary.withValues(alpha: 0.34),
              width: 1.1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: palette.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(item.icon, color: palette.foreground, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.78,
                        ),
                        fontSize: 14,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _timeAgo(item.createdAt),
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.58,
                        ),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationPalette {
  final Color background;
  final Color foreground;

  const _NotificationPalette(this.background, this.foreground);
}

_NotificationPalette _paletteFor(AppNotificationVisualType type) {
  switch (type) {
    case AppNotificationVisualType.warning:
      return const _NotificationPalette(Color(0xFF524617), Color(0xFFFFD028));
    case AppNotificationVisualType.critical:
      return const _NotificationPalette(Color(0xFF4B1E23), Color(0xFFFF5B67));
    case AppNotificationVisualType.system:
      return const _NotificationPalette(Color(0xFF1C4A2B), Color(0xFF53D66B));
    case AppNotificationVisualType.energy:
      return const _NotificationPalette(Color(0xFF5B411A), Color(0xFFFFA321));
    case AppNotificationVisualType.info:
      return const _NotificationPalette(Color(0xFF153B5C), Color(0xFF3DA4FF));
  }
}

String _timeAgo(DateTime? dateTime) {
  if (dateTime == null) return 'Just now';

  final diff = DateTime.now().difference(dateTime.toLocal());

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';

  final weeks = (diff.inDays / 7).floor();
  return '${weeks}w ago';
}
