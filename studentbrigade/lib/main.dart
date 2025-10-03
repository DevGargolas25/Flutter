import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';
import 'View/nav_shell.dart';

import 'View/Auth0/auth_gate.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final base = buildLightTheme();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: GoogleFonts.robotoTextTheme(base.textTheme),
      ),
      home: const AuthGate(
        childWhenAuthed:
            NavShell(), // si hay sesión (u offline con sesión previa), entra aquí
      ),
    );
  }
}
