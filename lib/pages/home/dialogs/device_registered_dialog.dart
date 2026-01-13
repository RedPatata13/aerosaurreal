import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DeviceRegisteredDialog extends StatefulWidget {
  final String uid;
  final String code;

  const DeviceRegisteredDialog({
    super.key,
    required this.uid,
    required this.code,
  });

  @override
  State<DeviceRegisteredDialog> createState() => _DeviceRegisteredDialogState();
}

class _DeviceRegisteredDialogState extends State<DeviceRegisteredDialog> {
  final _nameController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveAndClose() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      final deviceName = _nameController.text.trim();
      await FirebaseFirestore.instance.collection('users').doc(widget.uid).set({
        'devices': FieldValue.arrayUnion([
          {
            'code': widget.code,
            'name': deviceName,
            'createdAt': Timestamp.now(),
          },
        ]),
      }, SetOptions(merge: true));

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add device: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SizedBox(
          width: 340,
          height: 380,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: theme.dialogBackgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close, color: theme.iconTheme.color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.secondary,
                    child: Icon(
                      Icons.check,
                      color: theme.colorScheme.onSecondary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Account Registered\nSuccessfully!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                          theme.inputDecorationTheme.fillColor ??
                          theme.cardColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextSelectionTheme(
                      data: TextSelectionThemeData(
                        selectionColor: theme.colorScheme.primary.withOpacity(
                          0.3,
                        ),
                        selectionHandleColor: theme.colorScheme.primary,
                      ),
                      child: TextField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        cursorColor: theme.colorScheme.primary,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize:
                              (theme.textTheme.bodyMedium?.fontSize ?? 14) - 1,
                          color: theme.colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor:
                              theme.inputDecorationTheme.fillColor ??
                              theme.cardColor,
                          border: InputBorder.none,
                          isDense: true,
                          hintText: 'Add Device Name (Optional)',
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                            fontWeight: FontWeight.w600,
                            fontSize:
                                (theme.textTheme.bodyMedium?.fontSize ?? 14) -
                                1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _saveAndClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Return to Account'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
