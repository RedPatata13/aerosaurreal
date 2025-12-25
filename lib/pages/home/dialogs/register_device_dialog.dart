import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'device_registered_dialog.dart';

class RegisterDeviceDialog extends StatefulWidget {
  final String uid;

  const RegisterDeviceDialog({super.key, required this.uid});

  @override
  State<RegisterDeviceDialog> createState() => _RegisterDeviceDialogState();
}

class _RegisterDeviceDialogState extends State<RegisterDeviceDialog> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      _controllers[index].text = value.substring(value.length - 1);
      _controllers[index].selection = const TextSelection.collapsed(offset: 1);
    }

    if (value.isNotEmpty && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    setState(() {});
  }

  void _onBackspace(int index) {
    if (index > 0 && _controllers[index].text.isEmpty) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      setState(() {});
    }
  }

  void _submit() {
    Navigator.of(context).pop();
    showDialog<void>(
      context: context,
      builder: (context) => DeviceRegisteredDialog(
        uid: widget.uid,
        code: _controllers.map((c) => c.text).join(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final isComplete = _controllers.every(
      (controller) => controller.text.isNotEmpty,
    );

    final dialogBg = isDark ? const Color(0xFF1F2228) : Colors.white;
    final dialogText = isDark
        ? const Color(0xFFB9C0CB)
        : const Color(0xFF374151);

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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 8.0;
                  final available = constraints.maxWidth - (gap * 5);
                  final rawWidth = available / 6;
                  final boxWidth = rawWidth.clamp(34.0, 46.0);

                  return Column(
                    children: [
                      Row(
                        children: [
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close,
                              color: isDark ? Colors.white : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        Icons.smartphone,
                        size: 82,
                        color: isDark
                            ? const Color(0xFF415A77)
                            : colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Enter the code shown on your device to add it to your account',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: dialogText,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (index) {
                          return Row(
                            children: [
                              SizedBox(
                                width: boxWidth,
                                height: 44,
                                child: Focus(
                                  onKeyEvent: (node, event) {
                                    if (event is KeyDownEvent &&
                                        event.logicalKey ==
                                            LogicalKeyboardKey.backspace) {
                                      _onBackspace(index);
                                    }
                                    return KeyEventResult.ignored;
                                  },
                                  child: _CodeBox(
                                    controller: _controllers[index],
                                    focusNode: _focusNodes[index],
                                    onChanged: (value) =>
                                        _onChanged(index, value),
                                    onSubmitted: (_) {
                                      if (index == 5 && isComplete) _submit();
                                    },
                                  ),
                                ),
                              ),
                              if (index != 5) const SizedBox(width: gap),
                            ],
                          );
                        }),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          onPressed: isComplete ? _submit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? const Color(0xFF415A77)
                                : colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            disabledBackgroundColor: isDark
                                ? const Color(0xFF2D3138)
                                : theme.disabledColor.withValues(alpha: 0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Register Device'),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CodeBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const _CodeBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  State<_CodeBox> createState() => _CodeBoxState();
}

class _CodeBoxState extends State<_CodeBox> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const navy = Color(0xFF1B263B);

    final fill = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD9D9D9);
    final border = isDark ? const Color(0xFF4A4A4A) : const Color(0xFFC8C8C8);

    final titleMedium =
        theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);

    final codeStyle = titleMedium.copyWith(
      fontWeight: FontWeight.w700,
      fontSize: (titleMedium.fontSize ?? 16) - 2,
      color: isDark ? const Color(0xFFF3F4F6) : navy,
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF4A4A4A) : const Color(0xFFC8C8C8),
        ),
      ),
      alignment: Alignment.center,
      child: TextSelectionTheme(
        data: TextSelectionThemeData(
          selectionColor: Colors.transparent,
          selectionHandleColor: isDark ? Colors.white : navy,
        ),
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.text,
          textCapitalization: TextCapitalization.characters,
          cursorColor: isDark ? Colors.white : navy,
          style: codeStyle,
          inputFormatters: [
            LengthLimitingTextInputFormatter(1),
            FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
            UpperCaseTextFormatter(),
          ],
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            filled: false,
            fillColor: Colors.transparent,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: widget.onChanged,
          onSubmitted: widget.onSubmitted,
        ),
      ),
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
