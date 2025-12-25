import 'package:aerosaur_2nd_sem/enum/active_icon.dart';
import 'package:flutter/material.dart';
import '../components/topnavbar.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            children: [
              TopNavbar(
                iconColor: isDark ? Colors.white : const Color(0xFF111827),
                onBack: () => Navigator.pop(context),
                activeAdd: false,
                activeIcon: TopNavActiveIcon.settings,
                onNotifications: () {
                  Navigator.pushNamed(context, '/notifications');
                },
              ),
              const SizedBox(height: 12),

              // Page content
              const Expanded(
                child: Center(child: Text('Settings Page Content')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
