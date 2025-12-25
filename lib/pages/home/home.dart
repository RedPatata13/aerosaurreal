import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/home_content.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _handleLogoutAndRedirect(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleLogoutAndRedirect(context);
      });
      return const SizedBox.shrink();
    }

    /// IMPORTANT:
    /// HomeContent already handles:
    /// - Firestore stream
    /// - user data
    /// - device logic
    /// - UI
    return const HomeContent();
  }
}
