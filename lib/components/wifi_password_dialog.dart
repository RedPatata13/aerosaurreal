import 'package:flutter/material.dart';

class WifiPasswordDialogResult {
  final String ssid;
  final String password;

  const WifiPasswordDialogResult({required this.ssid, required this.password});
}

class WifiPasswordDialog extends StatefulWidget {
  final String title;
  final String actionLabel;
  final String? initialSsid;
  final String? initialPassword;

  const WifiPasswordDialog({
    super.key,
    required this.title,
    required this.actionLabel,
    this.initialSsid,
    this.initialPassword,
  });

  @override
  State<WifiPasswordDialog> createState() => _WifiPasswordDialogState();
}

class _WifiPasswordDialogState extends State<WifiPasswordDialog> {
  late final TextEditingController _ssidController;
  late final FocusNode _ssidFocusNode;
  late final TextEditingController _passwordController;
  late final FocusNode _passwordFocusNode;
  bool _obscurePassword = true;

  bool get _isButtonEnabled =>
      _ssidController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _ssidController = TextEditingController(text: widget.initialSsid ?? '');
    _ssidController.addListener(_updateState);
    _ssidFocusNode = FocusNode();
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
    _ssidController.removeListener(_updateState);
    _passwordController.removeListener(_updateState);
    _ssidFocusNode.dispose();
    _passwordFocusNode.dispose();
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _close(bool shouldSubmit) {
    _ssidFocusNode.unfocus();
    _passwordFocusNode.unfocus();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pop(
        shouldSubmit
            ? WifiPasswordDialogResult(
                ssid: _ssidController.text.trim(),
                password: _passwordController.text,
              )
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
          height: 450,
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
                    'Choose the 2.4 GHz Wi-Fi network your device should join.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: dialogText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _ssidController,
                    focusNode: _ssidFocusNode,
                    autofocus: _ssidController.text.trim().isEmpty,
                    textInputAction: TextInputAction.next,
                    onSubmitted: (_) => _passwordFocusNode.requestFocus(),
                    decoration: const InputDecoration(
                      hintText: 'Wi-Fi SSID',
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    focusNode: _passwordFocusNode,
                    obscureText: _obscurePassword,
                    autofocus: _ssidController.text.trim().isNotEmpty,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) {
                      if (_isButtonEnabled) {
                        _close(true);
                      }
                    },
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
