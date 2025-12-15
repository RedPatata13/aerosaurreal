import 'package:flutter/material.dart';

//light theme
class AppTheme {
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: Colors.white,
    primaryColor: const Color(0xFF1B263B),
    cardColor: const Color(0xFFF1F1F1),

    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1B263B),
      onPrimary: Colors.white,
      surface: Color(0xFFF1F1F1),
      onSurface: Colors.black,
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

  //dark theme
  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF0E0F13),
    primaryColor: const Color(0xFF415A77),
    cardColor: const Color(0xFF1F2228),

    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF415A77),
      onPrimary: Colors.white,
      surface: Color(0xFF1F2228),
      onSurface: Colors.white,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF415A77),
        foregroundColor: Colors.white,
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1F2228),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    ),
  );
}
