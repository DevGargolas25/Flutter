// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:studentbrigade/Models/mapMod.dart';
import 'firebase_options.dart';
import 'services/sync_service.dart';
import 'VM/Adapter.dart';
import 'app_theme.dart'; // buildLightTheme()
import 'dark_theme.dart'; // buildDarkTheme()
import 'View/nav_shell.dart';
import 'View/Auth0/auth_gate.dart';
import 'View/news_screen.dart';
import 'VM/Orchestrator.dart';
import 'VM/AnalyticsVM.dart';
import 'View/pruebaDB.dart';
import 'View/light_sensor_snackbar_listener.dart';
// FlutterMap Tiles Cache
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'services/meeting_point_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa tiles de cache de mapa
  await FMTCObjectBoxBackend().initialise();
  await FMTCStore('mapStore').manage.create();

  // Guardar meeting points
  await MeetingPointStorage.saveMeetingPoints(MapData.meetingPoints);
  // Si la app se abre sin internet, los puedes cargar del almacenamiento local
  final localPoints = await MeetingPointStorage.loadMeetingPoints();
  if (localPoints.isNotEmpty) {
    print('Puntos cargados localmente:');
    for (var p in localPoints) {
      print('${p.name} -> ${p.latitude}, ${p.longitude}');
    }
  } else {
    0;
    print('No hay puntos guardados localmente');
  }

  // ✅ Offline-friendly: no intentes bajar fuentes en runtime
  GoogleFonts.config.allowRuntimeFetching = false;

  // ✅ Inicializa Firebase primero (puede fallar offline y no tumbamos la app)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init failed (offline or config issue): $e');
  }

  // ✅ Arranca SyncService SOLO después de Firebase.init e INYECTA un Adapter válido
  SyncService.I.start(adapter: Adapter());

  // ⚙️ No bloquees el arranque con Analytics
  unawaited(_setupAnalyticsSafe());

  runApp(const MyApp());

  // 🚀 Primer intento de flush (por si hay cola pendiente al abrir)
  unawaited(SyncService.I.kick());
}

Future<void> _setupAnalyticsSafe() async {
  try {
    final analytics = FirebaseAnalytics.instance;
    await analytics.setAnalyticsCollectionEnabled(true);
    await analytics.logAppOpen();

    final platformLabel = kIsWeb
        ? 'web'
        : (defaultTargetPlatform == TargetPlatform.android
              ? 'android'
              : (defaultTargetPlatform == TargetPlatform.iOS
                    ? 'ios'
                    : 'other'));

    await analytics.logEvent(
      name: 'app_started',
      parameters: {
        'timestamp': DateTime.now().toIso8601String(),
        'platform': platformLabel,
      },
    );
    debugPrint('📊 Analytics: queued start events');
  } catch (e) {
    debugPrint('Analytics setup skipped: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

// 👇 Observa ciclo de vida para forzar flush al volver a primer plano
class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final _rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Orchestrator().disposeOrchestrator(); // cerrar sensor
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // ⏫ Al volver al foreground, intenta sincronizar lo pendiente
      unawaited(SyncService.I.kick());
    }
  }

  @override
  Widget build(BuildContext context) {
    final light = buildLightTheme();
    final dark = buildDarkTheme();

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: Orchestrator().themeMode,
      builder: (_, mode, __) {
        return MaterialApp(
          navigatorObservers: [AnalyticsNavObserver()],
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: _rootMessengerKey,

          // Listener para SnackBars del sensor de luz
          builder: (context, child) => LightSensorSnackBarListener(
            scaffoldMessengerKey: _rootMessengerKey,
            showDebugButton: false,
            child: child ?? const SizedBox.shrink(),
          ),

          // ✅ Con allowRuntimeFetching=false arriba, no hace requests de fuentes
          theme: light.copyWith(
            textTheme: GoogleFonts.robotoTextTheme(light.textTheme),
          ),
          darkTheme: dark.copyWith(
            textTheme: GoogleFonts.robotoTextTheme(dark.textTheme),
          ),
          themeMode: mode,

          home: const AuthGate(childWhenAuthed: NavShell()),
          routes: {
            TestFirebasePage.routeName: (_) => TestFirebasePage(),
            '/news': (context) => NewsScreen(orchestrator: Orchestrator()),
          },
        );
      },
    );
  }
}
