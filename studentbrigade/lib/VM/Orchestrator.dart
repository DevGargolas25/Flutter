// lib/Orchestrator/orchestrator.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

// ===== VMs =====
import 'ChatVM.dart';
import 'UserVM.dart';
import 'VideosVM.dart';
import 'AnalyticsVM.dart';
import 'MapVM.dart';
import 'EmergencyVM.dart';

// ===== Models =====
import '../Models/mapMod.dart';
import '../Models/videoMod.dart';
import '../Models/userMod.dart';
import '../Models/chatModel.dart';
import '../Models/emergencyMod.dart';

// ===== UI =====
import 'package:studentbrigade/View/video_detail_sheet.dart';

// ===== Sensor de luz / tema =====
import 'theme_sensor_service.dart';

// (Opcional) para permitir override manual del usuario
enum ThemeOverride { followSystem, autoByLight, forceLight, forceDark }

class Orchestrator extends ChangeNotifier with WidgetsBindingObserver {
  // ---------- Singleton ----------
  static final Orchestrator _instance = Orchestrator._internal();
  factory Orchestrator() => _instance;

  // ---------- VMs ----------
  late final MapVM _mapVM;
  late final VideosVM _videoVM;
  late final UserVM _userVM;
  late final ChatVM _chatVM;
  late final EmergencyVM _emergencyVM;

  // ---------- Navegación ----------
  int _currentPageIndex = 0;

  // ---------- Tema por sensor ----------
  final ThemeSensorService _themeSensor = ThemeSensorService(
    darkEnterLux: 10, // umbral para entrar a modo oscuro
    lightEnterLux: 80, // umbral para volver a claro
    smoothWindow: 5, // suavizado
  );

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);
  ThemeOverride _override = ThemeOverride.autoByLight;

  Orchestrator._internal() {
    // Instancias de VMs
    _mapVM = MapVM();
    _videoVM = VideosVM(VideosInfo());
    _userVM = UserVM();
    _chatVM = ChatVM(baseUrl: 'http://127.0.0.1:8080'); // emulador Android
    _chatVM.addListener(notifyListeners);

    // EmergencyVM con hooks hacia Analytics/DAO si los necesitas
    _emergencyVM = EmergencyVM(
      onLocationSaved: (lat, lng, ts) {
        // Envía a Analytics/DAO si aplica
        // _analyticsVM.logEmergencyLocation(lat, lng, ts);
      },
      onCallDurationSaved: (secs) {
        // _analyticsVM.logCallDuration(secs);
      },
    );

    _loadInitialUser(); // TODO: reemplazar por el usuario autenticado

    // Observadores de ciclo de vida (sensor y medición de llamada)
    WidgetsBinding.instance.addObserver(this);

    // Sensor de luz → recomputar tema
    _themeSensor.addListener(_recomputeTheme);
    _themeSensor.start();
    _recomputeTheme();
  }
  List<ChatMessage> get chatMessages => _chatVM.messages;
  bool get chatIsTyping => _chatVM.isTyping;
  Future<void> sendChatMessage(String text) => _chatVM.sendUserMessage(text);
  void setChatBackendBaseUrl(String url) {
    _chatVM.baseUrl = url; // usa el setter de ChatVM
  }

  void refreshChatBackendBaseUrl() {
    _chatVM.baseUrl = _resolveBaseUrl();
  }

  // ---------- Limpieza explícita ----------
  void disposeOrchestrator() {
    WidgetsBinding.instance.removeObserver(this);

    _themeSensor.removeListener(_recomputeTheme);
    _themeSensor.dispose();

    // Si tus VMs necesitan limpieza, hazlo aquí
    // _mapVM.dispose(); etc.
  }

  // ---------- Theme / sensor ----------
  void _recomputeTheme() {
    final sys = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    ThemeMode resolved;
    switch (_override) {
      case ThemeOverride.forceLight:
        resolved = ThemeMode.light;
        break;
      case ThemeOverride.forceDark:
        resolved = ThemeMode.dark;
        break;
      case ThemeOverride.followSystem:
        resolved = (sys == Brightness.dark) ? ThemeMode.dark : ThemeMode.light;
        break;
      case ThemeOverride.autoByLight:
        resolved = _themeSensor.mode; // viene del servicio por lux (histeresis)
        break;
    }
    if (themeMode.value != resolved) themeMode.value = resolved;
  }

  void setThemeOverride(ThemeOverride o) {
    _override = o;
    _recomputeTheme();
  }

  /// Para emulador/PC: simular lux
  void themeDebugLux(num lux) => _themeSensor.debugSetLux(lux.toDouble());

  // Pausar/Reanudar servicios por ciclo de vida de la app
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Sensor de luz
    if (state == AppLifecycleState.resumed) _themeSensor.start();
    if (state == AppLifecycleState.paused) _themeSensor.stop();

    // Delegar a EmergencyVM (mide regreso tras llamada)
    _emergencyVM.didChangeAppLifecycleState(state);
  }

  // ---------- Sesión / bootstrap ----------
  Future<void> _loadInitialUser() async {
    await _userVM.fetchUserData('current-user-id');
  }

  // ---------- Navegación ----------
  int get currentPageIndex => _currentPageIndex;
  void navigateToPage(int index) {
    if (_currentPageIndex != index) {
      _currentPageIndex = index;
      notifyListeners();
    }
  }

  void navigateToChat() => navigateToPage(1);
  void navigateToMap() => navigateToPage(2);
  void navigateToProfile() => navigateToPage(4);
  void navigateToVideos() => navigateToPage(3);

  // ---------- Exponer VMs (solo lectura si quieres encapsular más) ----------
  MapVM get mapVM => _mapVM;
  VideosVM get videoVM => _videoVM;
  UserVM get userVM => _userVM;
  EmergencyVM get emergencyVM => _emergencyVM;
  ChatVM get chatVM => _chatVM;
  //------CHAT---------
  String _resolveBaseUrl() {
    // Si corres en Flutter Web:
    // - Si tu app web se sirve por http:// (flutter run -d chrome), puedes usar http://127.0.0.1:8080
    // - Si tu app web se sirve por https:// (hosting), DEBES usar backend https (ngrok, cloudflared).
    if (kIsWeb) {
      return const String.fromEnvironment(
        'BACKEND_URL',
        defaultValue: 'http://127.0.0.1:8080',
      );
    }

    // Plataformas nativas:
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Emulador Android
        return 'http://10.0.2.2:8080';
      case TargetPlatform.iOS:
        // Simulator iOS
        return 'http://localhost:8080';
      default:
        // Desktop (Windows/Mac/Linux)
        return 'http://127.0.0.1:8080';
    }
  }

  // Cambia dinámicamente cuando lo necesites:
  void useAndroidEmulatorBackend() {
    _chatVM.baseUrl = 'http://10.0.2.2:8080';
  }

  void useLanBackend(String pcLanIp) {
    // Para dispositivo físico: usa la IP local de tu PC, ej. 192.168.1.50
    _chatVM.baseUrl = 'http://$pcLanIp:8080';
  }

  // ---------- MAP ----------
  Future<UserLocation?> getCurrentLocation() => _mapVM.getCurrentLocation();
  void startLocationTracking() => _mapVM.startLocationTracking();
  void stopLocationTracking() => _mapVM.stopLocationTracking();

  List<MapLocation> getMeetingPoints() => _mapVM.getMeetingPoints();

  MapLocation? getClosestMeetingPoint() {
    final userLocation = _mapVM.currentUserLocation;
    if (userLocation == null) return null;
    return _mapVM.getClosestMeetingPoint(userLocation);
  }

  Future<List<RoutePoint>?> calculateRouteToClosestPoint() =>
      _mapVM.calculateRouteToClosestPoint();

  List<RoutePoint>? get meetingPointRoute => _mapVM.meetingPointRoute;
  List<RoutePoint>? get brigadistRoute => _mapVM.brigadistRoute;

  void clearRoute() => _mapVM.clearRoute();

  // Getters MAP
  UserLocation? get currentUserLocation => _mapVM.currentUserLocation;
  bool get isLocationLoading => _mapVM.isLocationLoading;
  String? get locationError => _mapVM.locationError;
  Duration? get routeCalculationTime => _mapVM.routeCalculationTime;
  Duration? get estimatedArrivalTime => _mapVM.estimatedArrivalTime;
  double? get routeDistance => _mapVM.routeDistance;
  bool get isCalculatingRoute => _mapVM.isCalculatingEmergencyRoute;

  // ---------- USER ----------
  User? getUserData() => _userVM.getUserData();

  Future<bool> updateUserData({
    String? emergencyName1,
    String? emergencyPhone1,
    String? emergencyName2,
    String? emergencyPhone2,
    String? bloodType,
    String? doctorName,
    String? doctorPhone,
    String? insuranceProvider,
    String? foodAllergies,
    String? environmentalAllergies,
    String? drugAllergies,
    String? severityNotes,
    String? dailyMedications,
    String? emergencyMedications,
    String? vitaminsSupplements,
    String? specialInstructions,
  }) {
    return _userVM.updateUserData(
      emergencyName1: emergencyName1,
      emergencyPhone1: emergencyPhone1,
      emergencyName2: emergencyName2,
      emergencyPhone2: emergencyPhone2,
      bloodType: bloodType,
      doctorName: doctorName,
      doctorPhone: doctorPhone,
      insuranceProvider: insuranceProvider,
      foodAllergies: foodAllergies,
      environmentalAllergies: environmentalAllergies,
      drugAllergies: drugAllergies,
      severityNotes: severityNotes,
      dailyMedications: dailyMedications,
      emergencyMedications: emergencyMedications,
      vitaminsSupplements: vitaminsSupplements,
      specialInstructions: specialInstructions,
    );
  }

  // Methods on UserVM to get Brigadist in map of emergency
  Future<Brigadist?> getClosestBrigadist(double userLat, double userLon) async {
    return await _userVM.getClosestBrigadist(userLat, userLon);
  }

  Future<Brigadist?> getAssignedBrigadist(String emergencyId) async {
    return await _userVM.getAssignedBrigadist(emergencyId);
  }

  Future<Duration?> calculateRouteToBrigadist(
      double brigadistLat,
      double brigadistLng,
      ) async {
    try {
      // Llama al MapVM y espera el resultado
      final routeTime = await _mapVM.calculateRouteToBrigadist(
        brigadistLat,
        brigadistLng,
      );

      notifyListeners(); // Notificar cambios a las vistas
      return routeTime;  // 🔹 Devolver el tiempo de cálculo
    } catch (e) {
      print('Error en Orchestrator calculando ruta: $e');
      rethrow;
    }
  }

  // === MÉTODO PARA ANALYTICS ===
  Map<String, dynamic> getRouteAnalytics() {
    return _mapVM.getEmergencyRouteAnalytics();
  }

  Brigadist? get assignedBrigadist => _userVM.assignedBrigadist;

  // VIDEO OPERATIONS
  void openVideoDetails(BuildContext context, VideoMod v) {
    _videoVM.play(v);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VideoDetailsSheet(video: v),
    );
  }

  // ---------- EMERGENCY (orquestador only: delega a VMs) ----------
  /// Llama al brigadista: orquesta cálculo de ruta (MapVM) y luego delega a EmergencyVM para
  /// abrir dialer / guardar info adicional. No contiene lógica de negocio.
  Future<void> callBrigadistWithLocation(String phone) async {
    try {
      // 1) Intentar obtener brigadista asignado desde UserVM/EmergencyVM
      Brigadist? assigned = _emergencyVM.lastEmergency != null && _emergencyVM.lastEmergency!.assignedBrigadistId.isNotEmpty
          ? await _userVM.getAssignedBrigadist(_emergencyVM.lastEmergency!.assignedBrigadistId!)
          : _userVM.assignedBrigadist;

      Duration routeCalcTime = Duration.zero;

      // 2) Si hay brigadista con coords, calcular ruta (usar ubicación de la emergencia si existe)
      if (assigned != null && assigned.latitude != null && assigned.longitude != null) {
        final fromLat = _emergencyVM.lastLatitude ?? _mapVM.currentUserLocation?.latitude;
        final fromLng = _emergencyVM.lastLongitude ?? _mapVM.currentUserLocation?.longitude;

        final rt = await _mapVM.calculateRouteToBrigadist(
          assigned.latitude!,
          assigned.longitude!,
          fromLat: fromLat,
          fromLng: fromLng,
        );
        if (rt != null) routeCalcTime = rt;
      }

      // 3) Delegar a EmergencyVM para abrir dialer / persistir (EmergencyVM maneja guardar si hace falta)
      await _emergencyVM.callBrigadistWithLocation(
        phone,
        routeCalcTime: routeCalcTime,
        userId: _userVM.getUserData()?.studentId ?? _userVM.getUserData()?.email ?? 'unknown',
      );
    } catch (e) {
      debugPrint('Orchestrator.callBrigadistWithLocation error: $e');
      rethrow;
    }
  }

  /// Reporta una emergencia: orquesta persistencia (EmergencyVM), búsqueda de brigadista (UserVM),
  /// asignación (EmergencyVM) y cálculo de ruta (MapVM). Orchestrator NO persiste directamente.
  Future<void> reportEmergency({
    required EmergencyType type,
    double? latitude,
    double? longitude,
    String? description,
  }) async {
    try {
      final userId = _userVM.getUserData()?.studentId ?? _userVM.getUserData()?.email ?? 'unknown';

      // 1) Persistir la emergencia vía EmergencyVM (EmergencyVM decide cómo inferir LocationEnum o usar currentLocation)
      final em = await _emergencyVM.createEmergency(
        userId: userId,
        latitude: latitude,
        longitude: longitude,
        type: type,
        description: description,
      );

      if (em == null) {
        debugPrint('reportEmergency: failed to persist emergency');
        return;
      }

      // 2) Pedir al UserVM el brigadista más cercano (orquestador decide el punto de consulta)
      final queryLat = latitude ?? _emergencyVM.lastLatitude ?? _mapVM.currentUserLocation?.latitude;
      final queryLng = longitude ?? _emergencyVM.lastLongitude ?? _mapVM.currentUserLocation?.longitude;

      Brigadist? brig;
      if (queryLat != null && queryLng != null) {
        brig = await _userVM.getClosestBrigadist(queryLat, queryLng);
      } else {
        brig = await _userVM.getClosestBrigadist(0.0, 0.0);
      }

      if (brig == null) {
        debugPrint('reportEmergency: no brigadist available');
        return;
      }

      // 3) Asignar el brigadista en EmergencyVM (EmergencyVM actualiza su estado y DB si corresponde)
      _emergencyVM.setAssignedBrigadist(brig);

      // 4) Calcular ruta usando la ubicación de la emergencia como origen (si existe)
      final fromLat = latitude ?? _emergencyVM.lastLatitude ?? _mapVM.currentUserLocation?.latitude;
      final fromLng = longitude ?? _emergencyVM.lastLongitude ?? _mapVM.currentUserLocation?.longitude;

      await _mapVM.calculateRouteToBrigadist(
        brig.latitude ?? 0.0,
        brig.longitude ?? 0.0,
        fromLat: fromLat,
        fromLng: fromLng,
      );

      // 5) Opcional: actualizar secondsResponse en EmergencyVM basándose en el tiempo de cálculo
      if (_mapVM.routeCalculationTime != null) {
        await _emergencyVM.updateSecondsResponse(_mapVM.routeCalculationTime!.inSeconds);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('reportEmergency error: $e');
    }
  }

  // Accesores para EmergencyVM (ya expone emergencyVM getter más arriba)
  bool get isCalling => _emergencyVM.isCalling;
  int? get lastCallDurationSeconds => _emergencyVM.lastCallDurationSeconds;
  double? get lastLatitude => _emergencyVM.lastLatitude;
  double? get lastLongitude => _emergencyVM.lastLongitude;
  DateTime? get lastLocationAt => _emergencyVM.lastLocationAt;


}
