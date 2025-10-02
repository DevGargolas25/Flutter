import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';          // buildLightTheme()
import 'dark_theme.dart';        // buildDarkTheme()
import 'View/nav_shell.dart';
import 'View/chat_screen.dart';
import 'View/Auth0/auth_gate.dart';
import 'VM/Orchestrator.dart';   // 👈 importa el orquestador

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    Orchestrator().disposeOrchestrator(); // 👈 importante cerrar sensor
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final light = buildLightTheme();
    final dark = buildDarkTheme();

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: Orchestrator().themeMode, // 👈 escucha cambios del sensor
      builder: (_, mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: light.copyWith(
            textTheme: GoogleFonts.robotoTextTheme(light.textTheme),
          ),
          darkTheme: dark.copyWith(
            textTheme: GoogleFonts.robotoTextTheme(dark.textTheme),
          ),
          themeMode: mode, // 👈 aquí aplica claro/oscuro automático
          home: const AuthGate(
            childWhenAuthed: NavShell(),
          ),
          routes: {
            ChatScreen.routeName: (_) => const ChatScreen(),
          },
        );
      },
    );
  }
}



