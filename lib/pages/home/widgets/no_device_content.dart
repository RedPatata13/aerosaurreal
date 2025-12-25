import 'package:flutter/material.dart';

class NoDeviceContent extends StatelessWidget {
  final VoidCallback onRegisterDevice;
  final VoidCallback onLogout;

  const NoDeviceContent({
    super.key,
    required this.onRegisterDevice,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    const navy = Color(0xFF1B263B);
    const slate = Color(0xFF415A77);
    const danger = Color(0xFFC53A3A);
    final cardBg = isDark ? const Color(0xFF1F2228) : Colors.white;
    final cardBorder = isDark
        ? const Color(0xFF2B2F36)
        : const Color(0xFFD1D5DB);
    final titleColor = isDark
        ? const Color(0xFFF3F4F6)
        : const Color(0xFF111827);
    final bodyColor = isDark
        ? const Color(0xFFB9C0CB)
        : const Color(0xFF4B5563);
    final primaryButton = isDark ? slate : navy;
    final bodyMedium =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
    final titleMedium =
        theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cardBorder, width: 1.2),
              boxShadow: isDark
                  ? const []
                  : const [
                      BoxShadow(
                        color: Color(0x11000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 34, 18, 28),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'No devices registered on your account.',
                    textAlign: TextAlign.center,
                    style: titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "It appears you don't have any devices registered. Register your device now!",
                    textAlign: TextAlign.center,
                    style: bodyMedium.copyWith(color: bodyColor, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 330),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: onRegisterDevice,
                        icon: const Icon(Icons.link, size: 18),
                        label: const Text('Register new device'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryButton,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          textStyle: bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: (bodyMedium.fontSize ?? 14) - 1,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 40,
                    width: 120,
                    child: ElevatedButton.icon(
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout, size: 18),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: danger,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        textStyle: bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: (bodyMedium.fontSize ?? 14) - 1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
