import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart';          // buildLightTheme()
import 'dark_theme.dart';        // buildDarkTheme()
import 'View/nav_shell.dart';
import 'View/chat_screen.dart';
import 'View/Auth0/auth_gate.dart';
import 'VM/Orchestrator.dart';   // importa el orquestador
// FireBase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'View/pruebaDB.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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
    Orchestrator().disposeOrchestrator(); // cerrar sensor
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final light = buildLightTheme();
    final dark = buildDarkTheme();

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: Orchestrator().themeMode, // escucha cambios del sensor
      builder: (_, mode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: light.copyWith(
            textTheme: GoogleFonts.robotoTextTheme(light.textTheme),
          ),
          darkTheme: dark.copyWith(
            textTheme: GoogleFonts.robotoTextTheme(dark.textTheme),
          ),
          themeMode: mode, // aplica claro/oscuro automático
          home: const AuthGate(
            childWhenAuthed: NavShell(),
          ),
          routes: {
            ChatScreen.routeName: (_) => const ChatScreen(),
            TestFirebasePage.routeName: (_) => TestFirebasePage(),          },
        );
      },
    );
  }
}



