import 'package:flutter/material.dart';
import 'email_updated_page.dart';

class UpdateEmailDialog extends StatefulWidget {
  const UpdateEmailDialog({super.key});

  @override
  State<UpdateEmailDialog> createState() => _UpdateEmailDialogState();
}

class _UpdateEmailDialogState extends State<UpdateEmailDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  int _step = 0;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateState);
    _passwordController.addListener(_updateState);
  }

  void _updateState() {
    setState(() {});
  }

  bool get _isButtonEnabled {
    if (_step == 0) {
      return _passwordController.text.isNotEmpty;
    } else {
      return _emailController.text.isNotEmpty;
    }
  }

  void _nextStep() {
    if (!_isButtonEnabled) return;

    setState(() {
      if (_step == 0) {
        _step = 1;
      } else if (_step == 1) {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EmailUpdatedPage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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
          height: 370,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: dialogBg,
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
                        onPressed: () => Navigator.of(context).pop(),
                        iconSize: 20,
                        icon: Icon(
                          Icons.close,
                          color: isDark ? Colors.white : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _step == 0 ? 'Security Verification' : 'Update Email',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.textTheme.headlineMedium?.color,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    _step == 0
                        ? 'Enter your password'
                        : 'Enter your new email address',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: dialogText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 40),

                  if (_step == 0)
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: theme.iconTheme.color,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                    ),

                  if (_step == 1)
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'New Email',
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: 100,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _isButtonEnabled ? _nextStep : null,
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
                        _step == 0 ? 'Next' : 'Update',
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
