// lib/Orchestrator/orchestrator.dart
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:flutter/material.dart';

// ===== VMs =====
import 'ChatVM.dart';
import 'UserVM.dart';
import 'VideosVM.dart';
import 'MapVM.dart';
import 'EmergencyVM.dart';
import 'AnalyticsVM.dart';
import 'NewsVM.dart';

// ===== Models =====
import '../Models/mapMod.dart';
import '../Models/videoMod.dart';
import '../Models/userMod.dart';
import '../Models/chatModel.dart';
import '../Models/emergencyMod.dart';

// ===== UI =====
import 'package:studentbrigade/View/video_detail_sheet.dart'; //
import 'package:studentbrigade/View/Auth0/auth_service.dart';
import 'package:studentbrigade/VM/Adapter.dart';
import 'package:studentbrigade/services/offline_queue.dart';
import 'package:hive_flutter/hive_flutter.dart';

// ===== Sensor de luz / tema =====
import 'theme_sensor_service.dart';

// (Opcional) para permitir override manual del usuario
enum ThemeOverride { followSystem, autoByLight, forceLight, forceDark }

class Orchestrator extends ChangeNotifier with WidgetsBindingObserver {
  // ---------- Singleton ----------
  static final Orchestrator _instance = Orchestrator._internal();
  factory Orchestrator() => _instance;
  // emergencia seleccionada para mostrar en EmergencyPage
  Map<String, dynamic>? selectedEmergency;

  // ---------- VMs ----------
  late final MapVM _mapVM;
  late final VideosVM _videoVM;
  late final UserVM _userVM;
  late final ChatVM _chatVM;
  late final EmergencyVM _emergencyVM;
  late final AnalyticsVM _analyticsVM;
  late final NewsVM _newsVM;

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

  // Instancia de Adapter
  final Adapter adapter = Adapter();
  // NUEVO: para persistir ETA automáticamente
  String? _lastEtaPersistedForEmergencyKey;
  bool _etaPersistInFlight = false;
  // Última notificación del sensor de luz (para mostrar en UI)
  String? _lastLightSensorNotification;
  String? get lastLightSensorNotification => _lastLightSensorNotification;

  Orchestrator._internal() {
    // Instancias de VMs
    _mapVM = MapVM();
    _videoVM = VideosVM(VideosInfo(), adapter);
    _userVM = UserVM();

    // Inicializar AnalyticsVM con el adapter
    _analyticsVM = AnalyticsVM(adapter);

    // Inicializar NewsVM
    _newsVM = NewsVM();

    // Centraliza el baseUrl con _resolveBaseUrl
    _chatVM = ChatVM();
    _chatVM.addListener(notifyListeners);

    // EmergencyVM con hooks hacia Analytics/DAO si los necesitas
    _emergencyVM = EmergencyVM(
      onLocationSaved: (lat, lng, ts) {
        // _analyticsVM.logEmergencyLocation(lat, lng, ts);
      },
      onCallDurationSaved: (secs) {
        // _analyticsVM.logCallDuration(secs);
      },
       currentUserId: _userVM.getUserData()?.email,
    );

    // Inicializar MapVM para cargar meeting points
    _initializeMapVM();

    _loadInitialUser(); // TODO: reemplazar por el usuario autenticado

    // Observadores de ciclo de vida (sensor y medición de llamada)
    WidgetsBinding.instance.addObserver(this);

    // Sensor de luz → recomputar tema
    _themeSensor.addListener(_recomputeTheme);
    // Conectar callback: solo logging; ThemeSensorService guarda en BD
    _themeSensor.onResponseMeasured = (duration, newMode) {
      final ms = duration.inMilliseconds;
      final modeName = newMode == ThemeMode.dark ? 'modo oscuro' : 'modo claro';
      debugPrint(
        'Sensor de luz: respuesta ${ms}ms → $modeName (persistido en DB)',
      );
      // No notificar a la UI aquí para evitar snackbars/notificaciones.
    };

    _themeSensor.start();
    _recomputeTheme();

    // NUEVO: escuchar MapVM para persistir ETA cuando esté disponible
    _mapVM.addListener(_onMapVmUpdated);
  }

  /// Inicializa el MapVM y sus datos
  void _initializeMapVM() async {
    try {
      await _mapVM.initialize();
      print('✅ Orchestrator: MapVM inicializado correctamente');
    } catch (e) {
      print('❌ Orchestrator: Error inicializando MapVM: $e');
    }
  }

  void _onMapVmUpdated() async {
    if (_etaPersistInFlight) return;
    final eta = _mapVM.estimatedArrivalTime;
    final key = _emergencyVM.lastEmergencyDbKey;
    if (eta == null || key == null || key.isEmpty) return;
    if (_lastEtaPersistedForEmergencyKey == key)
      return; // ya persistido para esta emergency

    _etaPersistInFlight = true;
    try {
      final secs = (eta.inMilliseconds / 1000).ceil();
      await _emergencyVM.updateSecondsResponse(secs);
      _lastEtaPersistedForEmergencyKey = key;
    } catch (e) {
      debugPrint('⚠️ No se pudo persistir ETA como seconds_response: $e');
    } finally {
      _etaPersistInFlight = false;
    }
  }

  // ---------- Exponer VMs ----------
  MapVM get mapVM => _mapVM;
  VideosVM get videoVM => _videoVM;
  UserVM get userVM => _userVM;
  EmergencyVM get emergencyVM => _emergencyVM;
  ChatVM get chatVM => _chatVM;
  AnalyticsVM get analyticsVM => _analyticsVM;
  NewsVM get newsVM => _newsVM;

  // ---------- Limpieza explícita ----------
  void disposeOrchestrator() {
    WidgetsBinding.instance.removeObserver(this);

    _themeSensor.removeListener(_recomputeTheme);
    _themeSensor.dispose();

    // Quitar listener de MapVM
    _mapVM.removeListener(_onMapVmUpdated);

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
        // DEBUG: mostrar userType y mapa para verificar carga
        try {
          debugPrint('Bootstrap: userType=${user.userType}');
          debugPrint('Bootstrap: userMap=${user.toMap()}');
        } catch (e) {
          debugPrint('Bootstrap: error serializing user for debug: $e');
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Bootstrap user error: $e');
    }
  }

  // Public: cargar usuario por email (llamar desde AuthService tras login)
  Future<User?> loadUserByEmail(String email) async {
    try {
      // Use UserVM which implements offline-first cache -> RTDB logic
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

  /// Devuelve el Map crudo del usuario consultando directamente el Adapter
  /// (usa `Adapter.getUserByEmail`) — útil si necesitas los campos tal cual
  /// como vienen de RTDB o la clave `id`.
  Future<Map<String, dynamic>?> loadUserMapByEmail(String email) async {
    try {
      final em = email.trim().toLowerCase();
      final map = await adapter.getUserByEmail(em);
      if (map == null) {
        debugPrint('loadUserMapByEmail: no se encontró map para $em');
        return null;
      }
      debugPrint('loadUserMapByEmail: encontrado map keys=${map.values.toList()}');
      return map;
    } catch (e) {
      debugPrint('loadUserMapByEmail error: $e');
      return null;
    }
  }

  

  /// Carga un usuario completo por su `userId` (clave en RTDB).
  /// Devuelve `null` si no existe o si ocurre un error.
  Future<User?> loadUserById(String userId) async {
    try {
      final map = await adapter.getUser(userId);
      if (map == null) return null;
      final u = User.fromMap(map);
      return u;
    } catch (e) {
      debugPrint('loadUserById error: $e');
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

  // (duplicated getters removed)

  // ------ CHAT: resolver baseUrl según plataforma ---------
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

  /// Inicializa el chat con un prompt especializado para emergencias en tiempo real
  void startEmergencyChat({String? customPrompt}) {
    final defaultPrompt =
        'Eres un asistente de emergencias en tiempo real para una brigada estudiantil. '
        'Responde de forma breve, clara y priorizando la seguridad. '
        'Proporciona pasos accionables inmediatos y confirma si la persona está a salvo. '
        'Si detectas riesgo vital, sugiere llamar al 911 e informar la ubicación. '
        'Adapta tus indicaciones al contexto (incendio, sismo, herida, desmayo, etc.).';
    _chatVM.resetWithSystemPrompt(
      customPrompt?.trim().isNotEmpty == true
          ? customPrompt!.trim()
          : defaultPrompt,
    );
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
    // Si getClosestMeetingPoint acepta null internamente, podrías simplificar:
    // return _mapVM.getClosestMeetingPoint(_mapVM.currentUserLocation);
  }

  Future<List<RoutePoint>?> calculateRouteToClosestPoint() =>
      _mapVM.calculateRouteToClosestPoint();

  List<RoutePoint>? get meetingPointRoute => _mapVM.meetingPointRoute;
  List<RoutePoint>? get brigadistRoute => _mapVM.brigadistRoute;

  void clearRoute() => _mapVM.clearRoute();

  /// Notifica al MapVM sobre cambios de conectividad
  void onConnectivityChanged() => _mapVM.onConnectivityChanged();

  /// Fuerza la recarga de meeting points
  Future<void> reloadMeetingPoints() => _mapVM.reloadMeetingPoints();

  // Getters MAP
  UserLocation? get currentUserLocation => _mapVM.currentUserLocation;
  bool get isLocationLoading => _mapVM.isLocationLoading;
  String? get locationError => _mapVM.locationError;
  Duration? get routeCalculationTime => _mapVM.routeCalculationTime;
  Duration? get estimatedArrivalTime => _mapVM.estimatedArrivalTime;
  double? get routeDistance => _mapVM.routeDistance;

  // FIX: ajusta al nombre real en MapVM (isCalculatingEmergencyRoute o isCalculatingRoute)
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

  // FIX: si este método recibe *emergencyId*, NO le pases un brigadistId.
  // Si necesitas buscar por ID de brigadista, crea en UserVM un método:
  // Future<Brigadist?> getBrigadistById(String brigadistId)
  Future<Brigadist?> getAssignedBrigadist(String emergencyId) async {
    return await _userVM.getAssignedBrigadist(emergencyId);
  }

  Future<Duration?> calculateRouteToBrigadist(
    double brigadistLat,
    double brigadistLng,
  ) async {
    try {
      final routeTime = await _mapVM.calculateRouteToBrigadist(
        brigadistLat,
        brigadistLng,
      );
      notifyListeners();
      return routeTime;
    } catch (e) {
      debugPrint('Error en Orchestrator calculando ruta: $e');
      rethrow;
    }
  }

  // === MÉTODO PARA ANALYTICS ===
  Map<String, dynamic> getRouteAnalytics() {
    return _mapVM.getEmergencyRouteAnalytics();
  }

  // === MÉTODO PARA EMERGENCY ANALYTICS ===
  Future<Map<String, dynamic>> getEmergencyAnalytics() async {
    return await _analyticsVM.getEmergencyAnalytics();
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

  // ---------- EMERGENCY ----------
  Future<void> callBrigadist(String phone) async {
    try {
      await _emergencyVM.callBrigadist(phone, _userVM.getUserData()?.email,);
    } catch (e) {
      debugPrint('Orchestrator.callBrigadist error: $e');
      rethrow;
    }
  }

  Future<void> persistEmergencyOffline({
    required EmergencyType type,
    Duration? routeCalcTime,
    String? assignedBrigadistId,
  }) async {
    try {
      final userId =
          _userVM.getUserData()?.email ??
          'unknown';

      await _emergencyVM.createEmergencyAndPersist(
        userId: userId,
        location: LocationEnum.RGD, // o ajusta según tu lógica
        secondsResponse: routeCalcTime != null
            ? (routeCalcTime.inMilliseconds / 1000).ceil()
            : 0,
        type: type,
        assignedBrigadistId: assignedBrigadistId,
      );
    } catch (e) {
      debugPrint('Orchestrator.PersistEmergencyOffline error: $e');
      rethrow;
    }
  }

  /// Devuelve las emergencias con status "Unattended"
  /// Carga las Unattended desde Firebase, las guarda en el VM y las devuelve.
  Future<List<Map<String, dynamic>>> loadUnattendedEmergencies() async {
    final maps = await adapter.getUnattendedEmergencies();
    return maps;

  }

    /// 👇 Nuevo: stream en tiempo real de Unattended
  Stream<List<Map<String, dynamic>>> unattendedEmergenciesStream() {
    return emergencyVM.unattendedStream;
  }

  Future<void> initHome() async {
    // Arranca stream de emergencias
    await emergencyVM.initUnattendedStream();

    // Carga videos si hace falta
    if (videoVM.videos.isEmpty) {
      await videoVM.init();
    }
  }

Future<void> attendEmergency({
  required String emergencyId,
  required String? brigadistId,
}) async {
  try {
    // ===================== ONLINE / ÉXITO NORMAL =====================
      try {
      debugPrint('attendEmergency: attempting online update for $emergencyId');
      // Envolver la llamada en un timeout para evitar que se quede colgada
      await adapter
          .updateEmergency(
        emergencyId,
        status: 'InProgress',
        brigadistId: brigadistId,
      )
          .timeout(const Duration(seconds: 6));

      debugPrint('attendEmergency: online update completed for $emergencyId');

      final all = await adapter.getInProgressEmergencies();
      selectedEmergency = all.firstWhere(
        (e) {
          final id = e['id'] ??
              e['emergencyID'] ??
              e['emergencyId'] ??
              e['emergency_id'];
          return id != null && id.toString() == emergencyId.toString();
        },
        orElse: () => <String, dynamic>{},
      );
    } catch (e) {
      // ===================== OFFLINE / ERROR: FALLBACK =====================
      debugPrint('attendEmergency: online path failed, using offline fallback: $e');

      // 1) Encolar actualización offline
      try {
        await OfflineQueue.enqueueUpdate('Emergency', emergencyId, {
          'status': 'InProgress',
          'brigadistId': brigadistId,
        });
      } catch (err) {
        debugPrint('attendEmergency: error en OfflineQueue: $err');
      }

      // 2) Intentar usar caché de unattended
      try {
        final cached = adapter.getCachedUnattendedEmergencies();
        final found = cached.firstWhere(
          (e) {
            final id = e['id'] ??
                e['emergencyID'] ??
                e['emergencyId'] ??
                e['emergency_id'];
            return id != null && id.toString() == emergencyId.toString();
          },
          orElse: () => <String, dynamic>{},
        );

        if (found.isNotEmpty) {
          final m = Map<String, dynamic>.from(found);
          m['status'] = 'InProgress';
          if (brigadistId != null) m['brigadistId'] = brigadistId;

          // Normalizar userId
          if (m['userId'] == null || m['userId'].toString().trim().isEmpty) {
            if (m['user'] is Map) {
              final u = Map<String, dynamic>.from(m['user']);
              if (u['email'] != null) m['userId'] = u['email'].toString();
            }
            if ((m['userId'] == null || m['userId'].toString().isEmpty) &&
                m['reporter'] is Map) {
              final r = Map<String, dynamic>.from(m['reporter']);
              if (r['email'] != null) m['userId'] = r['email'].toString();
            }
            if ((m['userId'] == null || m['userId'].toString().isEmpty) &&
                m['email'] != null) {
              m['userId'] = m['email'].toString();
            }
          }

          selectedEmergency = m;

          // 3) Intentar inyectar perfil desde Hive, pero SIN dejar que explote
          try {
            if (Hive.isBoxOpen('cached_users')) {
              final box = Hive.box('cached_users');
              String? possibleEmail =
                  m['userId']?.toString().toLowerCase();

              if ((possibleEmail == null || possibleEmail.isEmpty) &&
                  m['email'] != null) {
                possibleEmail = m['email'].toString().toLowerCase();
              }

              if (possibleEmail != null && possibleEmail.isNotEmpty) {
                debugPrint(
                    'Orchestrator: checking Hive for cached user -> $possibleEmail');
                final cachedUser = box.get(possibleEmail);
                if (cachedUser is Map) {
                  debugPrint(
                      'Orchestrator: found cached user for $possibleEmail');
                    m['reporter'] = Map<String, dynamic>.from(cachedUser);
                  m['reporter_cached'] = true;
                } else {
                  debugPrint(
                      'Orchestrator: no cached user for $possibleEmail');
                  m['reporter_cached'] = false;
                }
              } else {
                m['reporter_cached'] = false;
              }
              selectedEmergency = m;
            } else {
              debugPrint('Orchestrator: Hive box cached_users not open');
              m['reporter_cached'] = false;
              selectedEmergency = m;
            }
          } catch (err) {
            debugPrint('Orchestrator: Hive lookup error: $err');
            m['reporter_cached'] = false;
            selectedEmergency = m;
          }
        } else {
          selectedEmergency = {
            'id': emergencyId,
            'status': 'InProgress',
            if (brigadistId != null) 'brigadistId': brigadistId,
          };
        }
      } catch (err) {
        debugPrint('attendEmergency: error usando caché unattended: $err');
        selectedEmergency = {
          'id': emergencyId,
          'status': 'InProgress',
          if (brigadistId != null) 'brigadistId': brigadistId,
        };
      }
    }
  } catch (err, st) {
    // Cualquier cosa que se haya escapado
    debugPrint('attendEmergency: UNEXPECTED error: $err\n$st');
  } finally {
    // 🌟 ESTO SE EJECUTA SIEMPRE: online, offline, con error, sin error
    _currentPageIndex = 5; // tab Emergency
    notifyListeners();
  }
}


  /// Marca una emergencia como Resolved y limpia la selección.
  Future<void> resolveEmergency(String emergencyId) async {
    try {
      await adapter.updateEmergency(emergencyId, status: 'Resolved');
      // Si la emergencia seleccionada coincide, limpiarla
      final selId = selectedEmergency?['id'] ?? selectedEmergency?['emergencyID'] ?? selectedEmergency?['emergencyId'];
      if (selId != null && selId.toString() == emergencyId.toString()) {
        selectedEmergency = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('resolveEmergency error: $e');
      rethrow;
    }
  }

  /// Navegar a la pestaña Emergency sin cambiar nada más (por si la necesitas)
  void navigateToEmergency() {
    _currentPageIndex = 5;
    notifyListeners();
  }


  Future<void> reportEmergency({
    required EmergencyType type,
    double? latitude,
    double? longitude,
    String? description,
  }) async {
    try {
      final userId =
          _userVM.getUserData()?.email ??
          'unknown';

      // 1) Persistir la emergencia vía EmergencyVM
      final em = await _emergencyVM.createEmergencyAndPersist(
        userId: userId,
        location: (latitude != null && longitude != null)
            ? _emergencyVM.emergencyLocationEnumFromLatLng(latitude, longitude)
            : LocationEnum.RGD,
        secondsResponse: 0,
        type: type,
        // description: description,
      );

      if (em == null) {
        debugPrint('reportEmergency: failed to persist emergency');
        return;
      }

      // Reset marca para nueva emergency
      _lastEtaPersistedForEmergencyKey = null;

      // 2) Pedir brigadista más cercano
      final queryLat =
          latitude ??
          _emergencyVM.lastLatitude ??
          _mapVM.currentUserLocation?.latitude;
      final queryLng =
          longitude ??
          _emergencyVM.lastLongitude ??
          _mapVM.currentUserLocation?.longitude;

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

      // 3) Asignar el brigadista en EmergencyVM
      _emergencyVM.setAssignedBrigadist(brig);

      // 4) Calcular ruta desde la ubicación de la emergencia si existe
      final fromLat =
          latitude ??
          _emergencyVM.lastLatitude ??
          _mapVM.currentUserLocation?.latitude;
      final fromLng =
          longitude ??
          _emergencyVM.lastLongitude ??
          _mapVM.currentUserLocation?.longitude;

      final rt = await _mapVM.calculateRouteToBrigadist(
        brig.latitude ?? 0.0,
        brig.longitude ?? 0.0,
        fromLat: fromLat,
        fromLng: fromLng,
      );

      // 5) Actualizar secondsResponse en EmergencyVM usando el ETA (ceil de ms→s)
      final durationForSecs = _mapVM.estimatedArrivalTime ?? rt;
      if (durationForSecs != null) {
        final secs = (durationForSecs.inMilliseconds / 1000).ceil();
        await _emergencyVM.updateSecondsResponse(secs);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('reportEmergency error: $e');
    }
  }

  // Accesores para EmergencyVM
  bool get isCalling => _emergencyVM.isCalling;
  int? get lastCallDurationSeconds => _emergencyVM.lastCallDurationSeconds;
  double? get lastLatitude => _emergencyVM.lastLatitude;
  double? get lastLongitude => _emergencyVM.lastLongitude;
  DateTime? get lastLocationAt => _emergencyVM.lastLocationAt;
}
