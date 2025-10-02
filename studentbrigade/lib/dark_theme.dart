// lib/dark_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

ThemeData buildDarkTheme() {
  final poppins = GoogleFonts.poppinsTextTheme().copyWith(
    headlineLarge: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w600, color: Colors.white),
    headlineMedium: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
    titleLarge: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
    titleMedium: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
    bodyLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white70),
    bodyMedium: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400, color: Colors.white70),
    labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: ColorScheme.dark(
      primary: darkPrimary,
      onPrimary: darkOnPrimary,
      secondary: greenShade,
      surface: darkSurface,
      onSurface: darkOnSurface,
      error: pastelRed,
    ),
    textTheme: poppins,

    appBarTheme: AppBarTheme(
      backgroundColor: darkSurface,
      surfaceTintColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
      iconTheme: const IconThemeData(color: Colors.white),
    ),

    iconTheme: const IconThemeData(color: Colors.white70),

    cardTheme: CardThemeData(
      color: darkSurface,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      shadowColor: softTeal.withOpacity(0.25),
    ),

    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      iconColor: softTeal,
      textColor: Colors.white,
      tileColor: darkSurface,
    ),

    chipTheme: ChipThemeData(
      labelStyle: GoogleFonts.poppins(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      backgroundColor: softTealLight.withOpacity(0.3),
      selectedColor: softTeal,
      side: BorderSide(color: softTeal.withOpacity(0.5)),
      shape: const StadiumBorder(),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: softTeal, width: 1.6),
      ),
      prefixIconColor: softTeal,
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: pastelRed,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: darkSurface,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: softTeal,
      unselectedItemColor: Colors.white60,
      selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 12),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkSurface,
      contentTextStyle: GoogleFonts.poppins(color: Colors.white),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    dividerTheme: const DividerThemeData(
      color: Colors.white24,
      thickness: 1,
      space: 16,
    ),
  );
}
