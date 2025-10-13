import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_theme.dart'; // buildLightTheme()
import 'dark_theme.dart'; // buildDarkTheme()
import 'View/nav_shell.dart';
import 'View/Auth0/auth_gate.dart';
import 'VM/Orchestrator.dart'; // importa el orquestador
import 'VM/AnalyticsVM.dart'; // importa el VM de Analytics
// FireBase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'View/pruebaDB.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final analytics = FirebaseAnalytics.instance;
  await analytics.setAnalyticsCollectionEnabled(true);
  await analytics.logAppOpen();

  await analytics.logEvent(
    name: 'app_started',
    parameters: {
      'timestamp': DateTime.now().toIso8601String(),
      'platform': 'web',
    },
  );
  print('📊 Analytics: Test event sent on app start');

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
          navigatorObservers: [AnalyticsNavObserver()],
          debugShowCheckedModeBanner: false,
          theme: light.copyWith(
            textTheme: GoogleFonts.robotoTextTheme(light.textTheme),
          ),
          darkTheme: dark.copyWith(
            textTheme: GoogleFonts.robotoTextTheme(dark.textTheme),
          ),
          themeMode: mode, // aplica claro/oscuro automático
          home: const AuthGate(childWhenAuthed: NavShell()),
          routes: {TestFirebasePage.routeName: (_) => TestFirebasePage()},
        );
      },
    );
  }
}
