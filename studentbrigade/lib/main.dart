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
// SnackBar de sensor de luz
import 'View/light_sensor_snackbar_listener.dart';
// FlutterMap Tiles Cache
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa Firebase con opciones generadas por FlutterFire
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializa tiles de cache de mapa
  await FMTCObjectBoxBackend().initialise();
  await FMTCStore('mapStore').manage.create();

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
  final _rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

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
          scaffoldMessengerKey: _rootMessengerKey,
          // Envuelve toda la app con el listener para mostrar SnackBars del sensor
          builder: (context, child) => LightSensorSnackBarListener(
            scaffoldMessengerKey: _rootMessengerKey,
            showDebugButton: false, // pon true si quieres ver los botones Sol/Luna de prueba
            child: child ?? const SizedBox.shrink(),
          ),
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