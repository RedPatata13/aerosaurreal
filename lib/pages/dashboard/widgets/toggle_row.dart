import 'package:flutter/material.dart';

class ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final TextStyle labelStyle;

  const ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.labelStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: labelStyle)),
        Transform.scale(
          scale: 1.05,
          child: Switch.adaptive(value: value, onChanged: onChanged),
        ),
      ],
    );
  }
}
