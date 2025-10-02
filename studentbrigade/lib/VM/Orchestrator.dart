import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:studentbrigade/View/video_detail_sheet.dart';

// VM clases
import 'ChatVM.dart';
import 'UserVM.dart';
import 'VideosVM.dart';
import 'AnalyticsVM.dart';
import 'MapVM.dart';

// Models
import '../Models/mapMod.dart';
import '../Models/videoMod.dart';
import '../Models/userMod.dart';

// NUEVO: servicio del sensor de luz
import 'theme_sensor_service.dart';

// (Opcional) para permitir override manual del usuario
enum ThemeOverride { followSystem, autoByLight, forceLight, forceDark }

class Orchestrator extends ChangeNotifier with WidgetsBindingObserver { // NUEVO: observer
  // Singleton
  static final Orchestrator _instance = Orchestrator._internal();
  factory Orchestrator() => _instance;

  // VMs
  late final MapVM _mapVM;
  late final VideosVM _videoVM;
  late final UserVM _userVM;

  // Navegación
  int _currentPageIndex = 0;

  // ====== NUEVO: Tema por sensor ======
  final ThemeSensorService _themeSensor = ThemeSensorService(
    darkEnterLux: 10,   // ajusta a gusto
    lightEnterLux: 80,  // ajusta a gusto
    smoothWindow: 5,
  );
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);
  ThemeOverride _override = ThemeOverride.autoByLight;
  // =====================================

  Orchestrator._internal() {
    _mapVM = MapVM();
    _videoVM = VideosVM(VideosInfo());
    _userVM = UserVM();
    _loadInitialUser(); // TODO: cambiar por quien inicie sesión

    // ====== NUEVO: iniciar sensor y escuchar cambios ======
    WidgetsBinding.instance.addObserver(this);
    _themeSensor.addListener(_recomputeTheme);
    _themeSensor.start();        // comienza a escuchar lux
    _recomputeTheme();           // fija tema inicial
    // ======================================================
  }

  // IMPORTANTE: llámalo cuando cierres la app (desde MyApp.dispose)
  void disposeOrchestrator() {
    WidgetsBinding.instance.removeObserver(this);
    _themeSensor.removeListener(_recomputeTheme);
    _themeSensor.dispose();
  }

  // ====== NUEVO: lógica para decidir ThemeMode final ======
  void _recomputeTheme() {
    final sys = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    ThemeMode resolved;
    switch (_override) {
      case ThemeOverride.forceLight: resolved = ThemeMode.light; break;
      case ThemeOverride.forceDark:  resolved = ThemeMode.dark;  break;
      case ThemeOverride.followSystem:
        resolved = (sys == Brightness.dark) ? ThemeMode.dark : ThemeMode.light;
        break;
      case ThemeOverride.autoByLight:
        resolved = _themeSensor.mode; // viene del sensor (con histeresis)
        break;
    }
    if (themeMode.value != resolved) themeMode.value = resolved;
  }

  // (Opcional) para ofrecer un menú de ajustes y cambiar la política
  void setThemeOverride(ThemeOverride o) {
    _override = o;
    _recomputeTheme();
  }

  // Permite simular lux en emulador/PC
  void themeDebugLux(num lux) => _themeSensor.debugSetLux(lux.toDouble());
  // ========================================================

  // Ciclo de vida: pausa/reanuda sensor
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed)  _themeSensor.start();
    if (state == AppLifecycleState.paused)   _themeSensor.stop();
  }

  // ===== Tu código tal cual =====
  Future<void> _loadInitialUser() async {
    await _userVM.fetchUserData('current-user-id');
  }

  int get currentPageIndex => _currentPageIndex;
  MapVM get mapVM => _mapVM;
  VideosVM get videoVM => _videoVM;
  UserVM get userVM => _userVM;

  void navigateToPage(int index) {
    if (_currentPageIndex != index) {
      _currentPageIndex = index;
      notifyListeners();
    }
  }

  void navigateToMap()     => navigateToPage(2);
  void navigateToProfile() => navigateToPage(4);
  void navigateToVideos()  => navigateToPage(3);

  // MAP
  Future<UserLocation?> getCurrentLocation() async {
    return await _mapVM.getCurrentLocation();
  }

  void startLocationTracking() => _mapVM.startLocationTracking();
  void stopLocationTracking()  => _mapVM.stopLocationTracking();

  List<MapLocation> getMeetingPoints() => _mapVM.getMeetingPoints();

  MapLocation? getClosestMeetingPoint() {
    final userLocation = _mapVM.currentUserLocation;
    if (userLocation == null) return null;
    return _mapVM.getClosestMeetingPoint(userLocation);
  }

  Future<List<RoutePoint>?> calculateRouteToClosestPoint() async {
    return await _mapVM.calculateRouteToClosestPoint();
  }

  List<RoutePoint>? get currentRoute => _mapVM.currentRoute;

  void clearRoute() => _mapVM.clearRoute();

  // Getters
  UserLocation? get currentUserLocation => _mapVM.currentUserLocation;
  bool get isLocationLoading => _mapVM.isLocationLoading;
  String? get locationError => _mapVM.locationError;

  // USER
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
  }) async {
    return await _userVM.updateUserData(
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

  void openVideoDetails(BuildContext context, VideoMod v) {
    _videoVM.play(v);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VideoDetailsSheet(video: v),
    );
  }
}
