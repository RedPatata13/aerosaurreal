import 'package:flutter/material.dart';

import '../models/device.dart';

const Duration _deviceOnlineThreshold = Duration(minutes: 2);

class OfflineStatusBanner extends StatelessWidget {
  const OfflineStatusBanner({super.key, required this.device});

  final Device device;

  bool get _isOffline {
    final lastSeen = _lastReadingAt;
    if (lastSeen != null) {
      return DateTime.now().difference(lastSeen) > _deviceOnlineThreshold;
    }
    return device.isOnline == false;
  }

  DateTime? get _lastReadingAt {
    final updatedAtSec = device.lastReadingUpdatedAtSec;
    if (updatedAtSec == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(
      updatedAtSec * 1000,
      isUtc: true,
    ).toLocal();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOffline) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final lastReadingAt = _lastReadingAt;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.42),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(
              Icons.wifi_tethering_error_rounded,
              color: Color(0xFFF59E0B),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Device is currently offline',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lastReadingAt != null
                      ? 'Last reading was ${_formatRelative(lastReadingAt)} at ${_formatAbsolute(lastReadingAt)}.'
                      : 'Waiting for the next reading from this device.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.4,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRelative(DateTime value) {
    final diff = DateTime.now().difference(value);

    if (diff.inSeconds < 60) {
      return 'just now';
    }
    if (diff.inMinutes < 60) {
      final minutes = diff.inMinutes;
      return '$minutes minute${minutes == 1 ? '' : 's'} ago';
    }
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    }
    final days = diff.inDays;
    return '$days day${days == 1 ? '' : 's'} ago';
  }

  String _formatAbsolute(DateTime value) {
    final now = DateTime.now();
    final time = _formatTime(value);

    if (_isSameDate(value, now)) {
      return 'today at $time';
    }

    final months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final month = months[value.month - 1];
    return '$month ${value.day}, ${value.year} at $time';
  }

  String _formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
