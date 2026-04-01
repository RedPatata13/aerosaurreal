import 'package:flutter/material.dart';

class WifiPasswordDialogResult {
  final String password;

  const WifiPasswordDialogResult({
    required this.password,
  });
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

  @override
  void initState() {
    super.initState();
    _passwordController = TextEditingController(
      text: widget.initialPassword ?? '',
    );
    _passwordFocusNode = FocusNode();
  }

  @override
  void dispose() {
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
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.wifiName,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            decoration: const InputDecoration(hintText: 'Wi-Fi Password'),
            obscureText: true,
            autofocus: false,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _close(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => _close(true),
          child: Text(widget.actionLabel),
        ),
      ],
    );
  }
}
