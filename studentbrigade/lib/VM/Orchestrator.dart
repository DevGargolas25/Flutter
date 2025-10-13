// lib/Orchestrator/orchestrator.dart
import 'package:flutter/foundation.dart' show ChangeNotifier, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';


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

// ===== UI =====
import 'package:studentbrigade/View/video_detail_sheet.dart';//
import 'package:studentbrigade/View/Auth0/auth_service.dart';



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
  late final AnalyticsVM _analyticsVM;

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
    _chatVM = ChatVM(baseUrl: ''); // emulador Android
    _chatVM.addListener(notifyListeners);
    _analyticsVM = AnalyticsVM();

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

  // ---------- Exponer VMs ----------
  MapVM get mapVM => _mapVM;
  VideosVM get videoVM => _videoVM;
  UserVM get userVM => _userVM;
  EmergencyVM get emergencyVM => _emergencyVM;
  ChatVM get chatVM => _chatVM;
  AnalyticsVM get analyticsVM => _analyticsVM;

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

  // ---------- Inicio sesión / bootstrap ----------
  Future<void> _loadInitialUser() async {
    try {
      final restored = await AuthService.instance.restore();
      if (!restored) {
        _userVM.clearError();
        notifyListeners();
        return;
      }

      final email = AuthService.instance.currentUserEmail;
      if (email == null || email.isEmpty) {
        _userVM.clearError();
        debugPrint('Auth restaurado pero sin email (¿falta scope "email"?)');
        notifyListeners();
        return;
      }

      final user = await _userVM.fetchUserByEmail(email);
      if (user == null) {
        debugPrint('Bootstrap: usuario no encontrado para email: $email');
        // _userVM ya guarda el mensaje de error; UI puede leer userVM.errorMessage
      } else {
        debugPrint('Bootstrap: usuario cargado: ${user.email}');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Bootstrap user error: $e');
    }
  }

    // Public: cargar usuario por email (llamar desde AuthService tras login)
  Future<User?> loadUserByEmail(String email) async {
    try {
      final u = await _userVM.fetchUserByEmail(email);
      if (u == null) {
        debugPrint('loadUserByEmail: usuario no encontrado ($email)');
      } else {
        debugPrint('loadUserByEmail: usuario cargado (${u.email})');
      }
      notifyListeners();
      return u;
    } catch (e) {
      debugPrint('loadUserByEmail error: $e');
      return null;
    }
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

  //------CHAT---------
    List<ChatMessage> get chatMessages => _chatVM.messages;
  bool get chatIsTyping => _chatVM.isTyping;

  /// Envía un mensaje del usuario al chat y dispara la respuesta de IA
  Future<void> sendChatMessage(String text) async {
    try {
      await _chatVM.sendMessage(text);
    } catch (e) {
      debugPrint('Orchestrator.sendChatMessage error: $e');
    }
  }

  /// Limpia el historial del chat
  void clearChat() {
    _chatVM.clearChat();
    notifyListeners();
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
  String? getUserErrorMessage() => _userVM.getErrorMessage();


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

  Future<void> calculateRouteToBrigadist(
    double brigadistLat,
    double brigadistLng,
  ) async {
    try {
      await _mapVM.calculateRouteToBrigadist(brigadistLat, brigadistLng);
      notifyListeners(); // Notificar cambios a las vistas
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

  // ---------- EMERGENCY (llamada + ubicación) ----------
  /// Llama al brigadista y captura lat/lng actuales antes de salir a la app de Teléfono.
  Future<void> callBrigadistWithLocation(String phone) =>
      _emergencyVM.callBrigadistWithLocation(phone);

  /// Accesores útiles para UI/analytics
  bool get isCalling => _emergencyVM.isCalling;
  int? get lastCallDurationSeconds => _emergencyVM.lastCallDurationSeconds;

  double? get lastLatitude => _emergencyVM.lastLatitude;
  double? get lastLongitude => _emergencyVM.lastLongitude;
  DateTime? get lastLocationAt => _emergencyVM.lastLocationAt;
}
