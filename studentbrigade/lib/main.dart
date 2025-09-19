import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // ✅ Agregar esta línea
import 'app_theme.dart';
import 'pages/nav_shell.dart';
import 'pages/chat_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme().copyWith(
        // ✅ Agregar Google Fonts a tu tema existente
        textTheme: GoogleFonts.robotoTextTheme(
          buildLightTheme().textTheme,
        ),
      ),
      home: const NavShell(),
      routes: {ChatScreen.routeName: (_) => const ChatScreen()},
    );
  }
}
