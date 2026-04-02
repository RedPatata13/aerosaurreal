import 'package:flutter/material.dart';

class NotificationToggleSection extends StatelessWidget {
  final List<NotificationToggleItem> items;

  const NotificationToggleSection({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101217),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A3037), width: 1.2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isFirst = index == 0;

          return Column(
            children: [
              SizedBox(
                height: 58,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    _MockupSwitch(value: item.value, onChanged: item.onChanged),
                  ],
                ),
              ),
              if (isFirst)
                const Divider(
                  color: Color(0xFF2A3037),
                  thickness: 1,
                  height: 1,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _MockupSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _MockupSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 62,
        height: 36,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: value ? const Color(0xFF4C6787) : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
          border: value ? null : Border.all(color: Colors.white, width: 2.2),
        ),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
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
