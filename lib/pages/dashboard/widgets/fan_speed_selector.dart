import 'package:flutter/material.dart';
import 'fan_speed_segment.dart';
import '/../../models/device.dart';

class FanSpeedSelector extends StatelessWidget {
  final FanSpeed value;
  final ValueChanged<FanSpeed> onChanged;
  final Color surfaceColor;
  final Color borderColor;
  final Color activeColor;
  final Color inactiveFill;
  final TextStyle textStyle;
  final Color inactiveTextColor;
  final Color activeTextColor;

  const FanSpeedSelector({
    required this.value,
    required this.onChanged,
    required this.surfaceColor,
    required this.borderColor,
    required this.activeColor,
    required this.inactiveFill,
    required this.textStyle,
    required this.inactiveTextColor,
    required this.activeTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: FanSpeedSegment(
              label: 'Slow',
              selected: value == FanSpeed.slow,
              onTap: () => onChanged(FanSpeed.slow),
              activeColor: activeColor,
              inactiveFill: inactiveFill,
              inactiveTextColor: inactiveTextColor,
              activeTextColor: activeTextColor,
              textStyle: textStyle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: FanSpeedSegment(
              label: 'Moderate',
              selected: value == FanSpeed.moderate,
              onTap: () => onChanged(FanSpeed.moderate),
              activeColor: activeColor,
              inactiveFill: inactiveFill,
              inactiveTextColor: inactiveTextColor,
              activeTextColor: activeTextColor,
              textStyle: textStyle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: FanSpeedSegment(
              label: 'Fast',
              selected: value == FanSpeed.fast,
              onTap: () => onChanged(FanSpeed.fast),
              activeColor: activeColor,
              inactiveFill: inactiveFill,
              inactiveTextColor: inactiveTextColor,
              activeTextColor: activeTextColor,
              textStyle: textStyle,
            ),
          ),
        ],
      ),
    );
  }
}
