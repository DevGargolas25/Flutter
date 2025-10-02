// lib/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Borde pastel sutil para tarjetas/controles (evita “línea negra”).
BorderSide _softBorder(Color base, [double opacity = .20]) =>
    BorderSide(color: base.withOpacity(opacity));

TextTheme _poppinsTextTheme(Color onText) {
  return GoogleFonts.poppinsTextTheme().copyWith(
    headlineLarge: GoogleFonts.poppins(
        fontSize: 28, fontWeight: FontWeight.w600, color: onText),
    headlineMedium: GoogleFonts.poppins(
        fontSize: 22, fontWeight: FontWeight.w600, color: onText),
    titleLarge: GoogleFonts.poppins(
        fontSize: 18, fontWeight: FontWeight.w600, color: onText),
    titleMedium: GoogleFonts.poppins(
        fontSize: 16, fontWeight: FontWeight.w600, color: onText),
    bodyLarge: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w400, color: onText),
    bodyMedium: GoogleFonts.poppins(
        fontSize: 13, fontWeight: FontWeight.w400, color: onText),
    labelLarge: GoogleFonts.poppins(
        fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
  );
}

/* ------------------------------ LIGHT THEME ------------------------------ */

ThemeData buildLightTheme() {
  final cs = const ColorScheme.light(
    primary: softTeal,         // turquesa
    onPrimary: Colors.white,
    secondary: greenShade,     // verde
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: darkGray,       // tinta
    background: lightNeutral,  // F7FBFC
    onBackground: darkGray,
    error: pastelRed,
    onError: Colors.white,
  );

  final tt = _poppinsTextTheme(cs.onSurface);

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: cs.background,
    textTheme: tt,

    appBarTheme: AppBarTheme(
      backgroundColor: cs.background,
      surfaceTintColor: Colors.transparent,
      foregroundColor: cs.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle:
      GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: cs.onSurface),
      iconTheme: IconThemeData(color: cs.onSurface),
    ),

    iconTheme: IconThemeData(color: cs.onSurface.withOpacity(.9)),

    // Tarjetas con borde suave (no negro)
    cardTheme: CardThemeData(
      color: cs.surface,
      surfaceTintColor: cs.surface,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: _softBorder(softTeal, .20),
      ),
      shadowColor: softTeal.withOpacity(.10),
    ),

    listTileTheme: ListTileThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      iconColor: cs.primary,
      textColor: cs.onSurface,
      tileColor: cs.surface,
    ),

    chipTheme: ChipThemeData(
      labelStyle: GoogleFonts.poppins(color: cs.onSurface, fontWeight: FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      backgroundColor: softTealLight,
      selectedColor: softTeal,
      side: BorderSide(color: softTeal.withOpacity(.25)),
      shape: const StadiumBorder(),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cs.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: _softBorder(const Color(0xFFE0E3E7), 1), // gris claro, sutil
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: _softBorder(const Color(0xFFE0E3E7), 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: softTeal, width: 1.6),
      ),
      prefixIconColor: softTeal,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: const MaterialStatePropertyAll(softTealLight),
        foregroundColor: const MaterialStatePropertyAll(Colors.white),
        shape: MaterialStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        elevation: const MaterialStatePropertyAll(0),
      ),
    ),

    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: const MaterialStatePropertyAll(softTeal),
        foregroundColor: const MaterialStatePropertyAll(Colors.white),
        shape: MaterialStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        elevation: const MaterialStatePropertyAll(0),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: const MaterialStatePropertyAll(softTeal),
        side: const MaterialStatePropertyAll(BorderSide(color: softTeal)),
        shape: MaterialStatePropertyAll(
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
      backgroundColor: cs.surface,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: cs.primary,
      unselectedItemColor: cs.onSurface.withOpacity(.55),
      selectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 12),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: cs.onSurface,
      contentTextStyle: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    dividerTheme: DividerThemeData(
      color: cs.onSurface.withOpacity(.08),
      thickness: 1,
      space: 16,
    ),
  );
}

