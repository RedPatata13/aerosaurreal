import 'package:flutter/material.dart';

class NotificationToggleSection extends StatelessWidget {
  final List<NotificationToggleItem> items;

  const NotificationToggleSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor, width: 1),
      ),
      elevation: 0,
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Column(
            children: [
              // Add vertical padding inside SwitchListTile
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SwitchListTile(
                  title: Text(item.label),
                  value: item.value,
                  onChanged: item.onChanged,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),

              // Only divider between Notifications and Alerts
              if (index == 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Divider(height: 0, color: theme.dividerColor),
                ),
            ],
          );
        }),
      ),
    );
  }
}

class NotificationToggleItem {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  NotificationToggleItem({
    required this.label,
    required this.value,
    required this.onChanged,
  });
}
