import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: GoogleFonts.roboto(
        textStyle: base.displayLarge,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: GoogleFonts.roboto(
        textStyle: base.displayMedium,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: GoogleFonts.roboto(
        textStyle: base.displaySmall,
        fontWeight: FontWeight.w600,
      ),

      headlineLarge: GoogleFonts.roboto(
        textStyle: base.headlineLarge,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: GoogleFonts.roboto(
        textStyle: base.headlineMedium,
        fontWeight: FontWeight.w500,
      ),
      headlineSmall: GoogleFonts.roboto(
        textStyle: base.headlineSmall,
        fontWeight: FontWeight.w500,
      ),

      titleLarge: GoogleFonts.roboto(
        textStyle: base.titleLarge,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: GoogleFonts.roboto(
        textStyle: base.titleMedium,
        fontWeight: FontWeight.w500,
      ),
      titleSmall: GoogleFonts.roboto(
        textStyle: base.titleSmall,
        fontWeight: FontWeight.w500,
      ),

      bodyLarge: GoogleFonts.roboto(textStyle: base.bodyLarge),
      bodyMedium: GoogleFonts.roboto(textStyle: base.bodyMedium),
      bodySmall: GoogleFonts.roboto(textStyle: base.bodySmall),

      labelLarge: GoogleFonts.roboto(textStyle: base.labelLarge),
      labelMedium: GoogleFonts.roboto(textStyle: base.labelMedium),
      labelSmall: GoogleFonts.roboto(textStyle: base.labelSmall),
    );
  }

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

    textTheme: _buildTextTheme(ThemeData.light().textTheme),
    primaryTextTheme: _buildTextTheme(ThemeData.light().primaryTextTheme),

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

    textTheme: _buildTextTheme(ThemeData.dark().textTheme),
    primaryTextTheme: _buildTextTheme(ThemeData.dark().primaryTextTheme),

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
