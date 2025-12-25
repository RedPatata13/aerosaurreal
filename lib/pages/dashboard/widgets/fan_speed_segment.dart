import 'package:flutter/material.dart';

class FanSpeedSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color activeColor;
  final Color inactiveFill;
  final Color inactiveTextColor;
  final Color activeTextColor;
  final TextStyle textStyle;

  const FanSpeedSegment({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.activeColor,
    required this.inactiveFill,
    required this.inactiveTextColor,
    required this.activeTextColor,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: selected ? activeColor : inactiveFill,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: textStyle.copyWith(
            color: selected ? activeTextColor : inactiveTextColor,
          ),
        ),
      ),
    );
  }
}
