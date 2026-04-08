import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../../components/app_dialogs.dart';

class SetPasswordDialog extends StatefulWidget {
  const SetPasswordDialog({super.key, required this.user});

  final User user;

  @override
  State<SetPasswordDialog> createState() => _SetPasswordDialogState();
}

class _SetPasswordDialogState extends State<SetPasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updateState);
    _confirmPasswordController.addListener(_updateState);
  }

  void _updateState() {
    setState(() {});
  }

  bool get _isButtonEnabled =>
      !_submitting &&
      _passwordController.text.isNotEmpty &&
      _confirmPasswordController.text.isNotEmpty &&
      _passwordController.text == _confirmPasswordController.text;

  Future<void> _submit() async {
    if (!_isButtonEnabled) return;

    final messenger = ScaffoldMessenger.of(context);
    final email = widget.user.email?.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (email == null || email.isEmpty) {
      await showAppMessageDialog(
        context,
        title: 'Email Required',
        message: 'Set and verify your email first before adding a password.',
      );
      return;
    }

    if (password.length < 6) {
      await showAppMessageDialog(
        context,
        title: 'Password Too Short',
        message: 'Password must be at least 6 characters long.',
      );
      return;
    }

    if (password != confirmPassword) {
      await showAppMessageDialog(
        context,
        title: 'Passwords Do Not Match',
        message: 'Make sure both password fields are the same.',
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await widget.user.linkWithCredential(credential);
      await widget.user.reload();

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      var message = 'Failed to set password.';
      switch (e.code) {
        case 'provider-already-linked':
          message = 'This account already has an email/password login.';
          break;
        case 'email-already-in-use':
        case 'credential-already-in-use':
          message = 'That email is already used by another account.';
          break;
        case 'invalid-credential':
          message = 'The email on this account is not ready to link yet.';
          break;
        case 'requires-recent-login':
          message = 'Please log in again before setting a password.';
          break;
        case 'weak-password':
          message = 'Password is too weak.';
          break;
      }

      messenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to set password: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _passwordController.removeListener(_updateState);
    _confirmPasswordController.removeListener(_updateState);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
          height: 405,
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
                        onPressed: () => Navigator.of(context).pop(),
                        iconSize: 20,
                        icon: Icon(
                          Icons.close,
                          color: isDark ? Colors.white : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'Set Password',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.textTheme.headlineMedium?.color,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Create a password login for this account.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: dialogText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 26),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'New Password',
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      hintText: 'Confirm Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
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
                      onPressed: _isButtonEnabled ? _submit : null,
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
                      child: _submitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
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
