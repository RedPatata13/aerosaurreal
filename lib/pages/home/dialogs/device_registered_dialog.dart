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
    final isDark = theme.brightness == Brightness.dark;

    const navy = Color(0xFF1B263B);

    final bodyMedium =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);

    final dialogBg = isDark ? const Color(0xFF1F2228) : Colors.white;
    final titleColor = isDark
        ? const Color(0xFFF3F4F6)
        : const Color(0xFF111827);

    final inputFill = isDark
        ? const Color(0xFF3A3A3A)
        : const Color(0xFFD9D9D9);
    final inputBorder = isDark
        ? const Color(0xFF4A4A4A)
        : const Color(0xFFC8C8C8);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SizedBox(
          width: 340,
          height: 380,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: dialogBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.close,
                          color: isDark ? Colors.white : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFF2E7D32),
                    child: Icon(Icons.check, color: Colors.white, size: 30),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Account Registered\nSuccessfully!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: inputFill,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: inputBorder),
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextSelectionTheme(
                      data: TextSelectionThemeData(
                        selectionColor: Colors.transparent,
                        selectionHandleColor: isDark ? Colors.white : navy,
                      ),
                      child: TextField(
                        controller: _nameController,
                        textAlign: TextAlign.center,
                        cursorColor: isDark ? Colors.white : navy,
                        style: bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: (bodyMedium.fontSize ?? 14) - 1,
                          color: isDark ? const Color(0xFFF3F4F6) : navy,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: inputFill,
                          border: InputBorder.none,
                          isDense: true,
                          hintText: 'Add Device Name (Optional)',
                          hintStyle: bodyMedium.copyWith(
                            color: const Color(0xFF9CA3AF),
                            fontWeight: FontWeight.w600,
                            fontSize: (bodyMedium.fontSize ?? 14) - 1,
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
                      style: isDark
                          ? ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF415A77),
                              foregroundColor: Colors.white,
                            )
                          : null,
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
