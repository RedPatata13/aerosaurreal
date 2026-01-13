import 'package:flutter/material.dart';
import '/../../models/device.dart';

class DeviceChip extends StatelessWidget {
  final Device device;
  final Color color;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onTogglePower;

  const DeviceChip({
    super.key,
    required this.device,
    required this.color,
    required this.selected,
    required this.onSelect,
    required this.onTogglePower,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 186,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? theme.colorScheme.primary : color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected
              ? theme.colorScheme.onPrimary.withOpacity(0.7)
              : Colors.transparent,
        ),
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              height: 44,
              child: InkWell(
                onTap: onTogglePower,
                borderRadius: BorderRadius.circular(12),
                child: Icon(
                  Icons.power_settings_new_rounded,
                  color: device.isOn
                      ? const Color(0xFF3AB54A)
                      : theme.colorScheme.onPrimary,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${device.id}\n${device.name}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: (theme.textTheme.bodyMedium ?? const TextStyle())
                    .copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      height: 1.2,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
