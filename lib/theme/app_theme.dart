import 'package:flutter/material.dart';

class AppTheme {
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    primaryColor: const Color(0xFF1B263B),
    cardColor: const Color(0xFFF1F1F1),

    dividerColor: const Color(0xFFCCCCCC),

    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1B263B),
      onPrimary: Colors.white,
      surface: Color(0xFFF1F1F1),
      onSurface: Colors.black,
    ),

    cardTheme: CardThemeData(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1B263B),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF1F1F1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    ),
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0E0F13),
    primaryColor: const Color(0xFF415A77),
    cardColor: const Color(0xFF1F2228),

    dividerColor: const Color(0xFF323232),

    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF415A77),
      onPrimary: Colors.white,
      surface: Color(0xFF1F2228),
      onSurface: Colors.white,
    ),

    cardTheme: CardThemeData(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF415A77),
        foregroundColor: Colors.white,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF414141),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
