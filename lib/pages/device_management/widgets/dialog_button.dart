import 'package:flutter/material.dart';

class DialogButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final Color borderColor;
  final Color foreground;
  final Color? background;

  const DialogButton({
    required this.label,
    required this.onPressed,
    required this.primary,
    required this.borderColor,
    required this.foreground,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buttonChild = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (primary) {
      return SizedBox(
        height: 42,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: background,
            foregroundColor: foreground,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) - 1,
            ),
          ),
          child: buttonChild,
        ),
      );
    }

    return SizedBox(
      height: 42,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: borderColor),
          foregroundColor: foreground,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) - 1,
          ),
        ),
        child: buttonChild,
      ),
    );
  }
}
