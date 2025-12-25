import 'package:flutter/material.dart';

class FilledInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final Color fill;

  const FilledInput({
    required this.controller,
    required this.hint,
    required this.fill,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark
        ? const Color(0xFFF3F4F6)
        : const Color(0xFF111827);
    final hintColor = isDark
        ? const Color(0xFF9CA3AF)
        : const Color(0xFF6B7280);
    final baseFontSize = theme.textTheme.bodyMedium?.fontSize ?? 14;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      child: TextSelectionTheme(
        data: const TextSelectionThemeData(selectionColor: Colors.transparent),
        child: TextField(
          controller: controller,
          cursorColor: textColor,
          textAlignVertical: TextAlignVertical.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: baseFontSize + 1,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            filled: true,
            fillColor: fill,
            contentPadding: EdgeInsets.zero,
            hintText: hint,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: hintColor,
              fontWeight: FontWeight.w600,
              fontSize: baseFontSize,
            ),
          ),
        ),
      ),
    );
  }
}
