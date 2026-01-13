import 'package:flutter/material.dart';

Future<void> showInfoDialog(
  BuildContext context, {
  required String title,
  required String body,
}) {
  final theme = Theme.of(context);

  return showDialog<void>(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SizedBox(
          width: 340,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.dialogBackgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    body,
                    textAlign: TextAlign.left,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.4,
                      fontSize:
                          (theme.textTheme.bodyMedium?.fontSize ?? 14) - 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      width: 140,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize:
                                (theme.textTheme.bodyMedium?.fontSize ?? 14) -
                                1,
                          ),
                        ),
                        child: const Text('Close'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
