import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../../../components/app_dialogs.dart';
import '../../../../firebase_options.dart';
import 'email_updated_page.dart';

class UpdateEmailDialog extends StatefulWidget {
  const UpdateEmailDialog({super.key, required this.user});

  final User user;

  @override
  State<UpdateEmailDialog> createState() => _UpdateEmailDialogState();
}

class _UpdateEmailDialogState extends State<UpdateEmailDialog> {
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_updateState);
  }

  void _updateState() {
    setState(() {});
  }

  bool get _isButtonEnabled => _emailController.text.trim().isNotEmpty;

  Future<bool> _emailAlreadyExists(String email) async {
    final uri = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/accounts:createAuthUri?key=${DefaultFirebaseOptions.currentPlatform.apiKey}',
    );

    final response = await http.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'identifier': email,
        'continueUri': 'http://localhost',
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Email validation failed (${response.statusCode}).');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['registered'] == true;
  }

  Future<void> _update() async {
    if (!_isButtonEnabled || _isSubmitting) return;

    final email = _emailController.text.trim();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _isSubmitting = true;
    });

    try {
      if (widget.user.email == email) {
        await showAppMessageDialog(
          context,
          title: 'Email Already Added',
          message: 'That email is already set on your account.',
        );
        return;
      }

      final emailExists = await _emailAlreadyExists(email);
      final currentEmail = widget.user.email?.trim().toLowerCase();
      final normalizedEmail = email.toLowerCase();

      if (emailExists && currentEmail != normalizedEmail) {
        await showAppMessageDialog(
          context,
          title: 'Email Already In Use',
          message: 'That email is already in use.',
        );
        return;
      }

      await widget.user.verifyBeforeUpdateEmail(email);
      await widget.user.reload();

      if (!mounted) return;
      navigator.pop();
      navigator.push(
        MaterialPageRoute(
          builder: (_) => EmailUpdatedPage(pendingEmail: email),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;

      var message = 'Failed to update email.';
      switch (e.code) {
        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;
        case 'email-already-in-use':
          message = 'That email is already in use.';
          break;
        case 'requires-recent-login':
          message = 'Please log in again before changing your email address.';
          break;
      }

      messenger.showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to update email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
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
                    'Update Email',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.textTheme.headlineMedium?.color,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 40),

                  Text(
                    'Enter your new email address',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: dialogText,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 40),

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
                      onPressed: _isButtonEnabled && !_isSubmitting
                          ? _update
                          : null,
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
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Update', textAlign: TextAlign.center),
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
