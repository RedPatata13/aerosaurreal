import 'package:flutter/material.dart';

class WifiPasswordDialogResult {
  final String password;

  const WifiPasswordDialogResult({required this.password});
}

class WifiPasswordDialog extends StatefulWidget {
  final String title;
  final String wifiName;
  final String actionLabel;
  final String? initialPassword;

  const WifiPasswordDialog({
    super.key,
    required this.title,
    required this.wifiName,
    required this.actionLabel,
    this.initialPassword,
  });

  @override
  State<WifiPasswordDialog> createState() => _WifiPasswordDialogState();
}

class _WifiPasswordDialogState extends State<WifiPasswordDialog> {
  late final TextEditingController _passwordController;
  late final FocusNode _passwordFocusNode;
  bool _obscurePassword = true;

  bool get _isButtonEnabled => _passwordController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController(
      text: widget.initialPassword ?? '',
    );
    _passwordController.addListener(_updateState);
    _passwordFocusNode = FocusNode();
  }

  void _updateState() {
    setState(() {});
  }

  @override
  void dispose() {
    _passwordController.removeListener(_updateState);
    _passwordFocusNode.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _close(bool shouldSubmit) {
    _passwordFocusNode.unfocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop(
        shouldSubmit
            ? WifiPasswordDialogResult(password: _passwordController.text)
            : null,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
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
          height: 390,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: dialogBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      IconButton(
                        onPressed: () => _close(false),
                        iconSize: 20,
                        icon: Icon(
                          Icons.close,
                          color: isDark ? Colors.white : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.textTheme.headlineMedium?.color,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    widget.wifiName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.textTheme.headlineMedium?.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Enter the password for this 2.4 GHz Wi-Fi network.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: dialogText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: _obscurePassword,
                    autofocus: false,
                    decoration: InputDecoration(
                      hintText: 'Wi-Fi Password',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 120,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _isButtonEnabled ? () => _close(true) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isButtonEnabled
                            ? (isDark
                                  ? const Color(0xFF415A77)
                                  : colorScheme.primary)
                            : (isDark
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300),
                        foregroundColor: _isButtonEnabled
                            ? colorScheme.onPrimary
                            : (isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade500),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        widget.actionLabel,
                        textAlign: TextAlign.center,
                      ),
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
