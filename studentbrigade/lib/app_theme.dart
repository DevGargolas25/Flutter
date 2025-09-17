import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

ThemeData buildLightTheme() {
  final baseScheme = ColorScheme.fromSeed(
    seedColor: softTeal,
    brightness: Brightness.light,
  );

  final poppins = GoogleFonts.poppinsTextTheme().copyWith(
    headlineLarge: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w600, color: darkGray),
    headlineMedium: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: darkGray),
    titleLarge: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: darkGray),
    titleMedium: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: darkGray),
    bodyLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: darkGray),
    bodyMedium: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400, color: darkGray),
    labelLarge: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
  );

  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: lightNeutral,
    colorScheme: ColorScheme.light(
      primary: softTeal,
      onPrimary: Colors.white,
      secondary: greenShade,
      surface: Colors.white,
      onSurface: darkGray,
      error: pastelRed,
    ),
    textTheme: poppins,

    appBarTheme: AppBarTheme(
      backgroundColor: lightNeutral,
      surfaceTintColor: Colors.transparent,
      foregroundColor: darkGray,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: darkGray),
      iconTheme: const IconThemeData(color: darkGray),
    ),

    // antes: darkGray.withOpacity(0.9)
    iconTheme: IconThemeData(color: darkGray.withValues(alpha: 0.9)),

    // Evita tinte en superficies
    cardTheme: CardThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      // antes: softTeal.withOpacity(0.10)
      shadowColor: softTeal.withValues(alpha: 0.10),
    ),

    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      iconColor: softTeal,
      textColor: darkGray,
      tileColor: Colors.white,
    ),

    chipTheme: ChipThemeData(
      labelStyle: GoogleFonts.poppins(color: darkGray, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      backgroundColor: softTealLight,
      selectedColor: softTeal,
      // antes: softTeal.withOpacity(0.25)
      side: BorderSide(color: softTeal.withValues(alpha: 0.25)),
      shape: const StadiumBorder(),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E3E7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE0E3E7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: softTeal, width: 1.6),
      ),
      prefixIconColor: softTeal,
    ),

    // === Botones con WidgetStatePropertyAll (no deprecated) ===
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: const WidgetStatePropertyAll(softTealLight),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        elevation: const WidgetStatePropertyAll(0),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: const WidgetStatePropertyAll(softTealLight),
        foregroundColor: const WidgetStatePropertyAll(Colors.white),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        elevation: const WidgetStatePropertyAll(0),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const WidgetStatePropertyAll(softTealLight),
        side: const WidgetStatePropertyAll(BorderSide(color: softTeal)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    ),

    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: pastelRed,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: CircleBorder(),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: softTeal,
      // antes: darkGray.withOpacity(0.55)
      unselectedItemColor: darkGray.withValues(alpha: 0.55),
      selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 12),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkGray,
      contentTextStyle: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    // antes: darkGray.withOpacity(0.08)
    dividerTheme: DividerThemeData(
      color: darkGray.withValues(alpha: 0.08),
      thickness: 1,
      space: 16,
    ),
  );
}
