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
          cursorColor: theme.colorScheme.onSurface,
          textAlignVertical: TextAlignVertical.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) + 1,
          ),
          decoration: InputDecoration(
            border: InputBorder.none,
            isDense: true,
            filled: true,
            fillColor: fill,
            contentPadding: EdgeInsets.zero,
            hintText: hint,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.hintColor ?? Colors.grey,
              fontWeight: FontWeight.w400,
              fontSize: theme.textTheme.bodyMedium?.fontSize ?? 14,
            ),
          ),
        ),
      ),
    );
  }
}
