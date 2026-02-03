import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'username_updated_page.dart';
import 'package:aerosaur_2nd_sem/services/api/api_exceptions.dart';
import 'package:aerosaur_2nd_sem/state/user_store.dart';

class UpdateUsernameDialog extends StatefulWidget {
  const UpdateUsernameDialog({super.key});

  @override
  State<UpdateUsernameDialog> createState() => _UpdateUsernameDialogState();
}

class _UpdateUsernameDialogState extends State<UpdateUsernameDialog> {
  final _usernameController = TextEditingController();
  bool _loading = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();

    _usernameController.addListener(() {
      if (!mounted) return;
      if (_errorText != null) {
        setState(() => _errorText = null);
      } else {
        setState(() {});
      }
    });
  }

  bool get _isButtonEnabled =>
      !_loading && _usernameController.text.trim().isNotEmpty;

  Future<void> _updateUsername() async {
    if (!_isButtonEnabled) return;

    setState(() {
      _loading = true;
      _errorText = null;
    });

    final newUsername = _usernameController.text.trim();

    try {
      await context.read<UserStore>().updateUsername(newUsername);

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(newUsername);
        await user.reload();
      }

      if (!mounted) return;

      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UsernameUpdatedPage()),
      );
    } on ApiException catch (e) {
      if (!mounted) return;

      if (e.statusCode == 409) {
        setState(() {
          _errorText = 'Username already exists.';
        });
        return;
      }

      setState(() {
        _errorText = (e.body['message'] ?? e.body['error'] ?? 'Update failed')
            .toString();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
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
                    'Update Username',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.textTheme.headlineMedium?.color,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text(
                    'Enter your new username',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: dialogText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(hintText: 'New Username'),
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _errorText!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 100,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _isButtonEnabled ? _updateUsername : null,
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
                      child: _loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
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
