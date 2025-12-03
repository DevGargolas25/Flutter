import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

// Modelo Emergency
import '../Models/emergencyMod.dart';
import '../Models/userMod.dart';

// Modelos del mapa (evitar colisiones de nombres)
import '../Models/mapMod.dart' as map;

// Adapter (Firebase RTDB)
import 'Adapter.dart';
import '../Caches/lruEmergencyCache';
import 'package:hive_flutter/hive_flutter.dart';

class EmergencyVM with ChangeNotifier, WidgetsBindingObserver {
  EmergencyVM({
    this.onLocationSaved,
    this.onCallDurationSaved,
    this.onEmergencyCreated,
    this.onEmergencyUpdated,
    this.currentUserId,
    Adapter? adapter, // inyección opcional (tests/mocks)
  }) : _adapter = adapter ?? Adapter() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Guarda en Hive los datos de los usuarios reportantes de las primeras 3
  /// emergencias de la lista. Es "fire-and-forget" para no bloquear el UI.
  Future<void> _saveFirst3Reporters(List<Map<String, dynamic>> list) async {
    try {
      if (list.isEmpty) return;
      final box = Hive.box('cached_users');

      final max = math.min(3, list.length);
      for (var i = 0; i < max; i++) {
        final em = list[i];
        // Soportar varias claves posibles que identifiquen al reporter
        final possible = <String?>[
          (em['userId'] ?? em['user'] ?? em['reporter'])?.toString(),
          (em['email'])?.toString(),
        ];

        String? idOrEmail;
        for (final p in possible) {
          if (p != null && p.trim().isNotEmpty) {
            idOrEmail = p.trim();
            break;
          }
        }
        if (idOrEmail == null) continue;

        Map<String, dynamic>? userMap;
        try {
          // Si contiene '@' lo tratamos como email
          if (idOrEmail.contains('@')) {
            userMap = await _adapter.getUserByEmail(idOrEmail);
          } else {
            // intentar por id
            userMap = await _adapter.getUser(idOrEmail);
            // si no se halló por id, intentar como email
            if (userMap == null && idOrEmail.contains('@')) {
              userMap = await _adapter.getUserByEmail(idOrEmail);
            }
          }
        } catch (e) {
          debugPrint('Error fetching reporter ($idOrEmail): $e');
        }

        if (userMap != null) {
          // Normalizar la key: preferir email si existe
          final key = (userMap['email'] as String?)?.toLowerCase() ?? (userMap['id'] as String? ?? idOrEmail);
          try {
            await box.put(key, Map<String, dynamic>.from(userMap));
          } catch (e) {
            debugPrint('Hive put failed for $key: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error in _saveFirst3Reporters: $e');
    }
  }

  // --- Dependencia a Firebase RTDB ---
  final Adapter _adapter;

  // --- Hooks opcionales ---
  final void Function(double lat, double lng, DateTime ts)? onLocationSaved;
  final void Function(int seconds)? onCallDurationSaved;
  final void Function(Emergency emergency)? onEmergencyCreated;
  final void Function(Emergency emergency)? onEmergencyUpdated;

  final String? currentUserId;

  // --- Estado público ---
  bool _isWorking = false;
  bool get isWorking => _isWorking;

  bool _isCalling = false;
  bool get isCalling => _isCalling;

  String? lastDialedPhone;
  double? lastLatitude;
  double? lastLongitude;
  DateTime? lastLocationAt;
  int? lastCallDurationSeconds;

  Emergency? lastEmergency;

  // ------- Unattended emergencies (stream + cache) -------
  final LruEmergencyCache unattendedCache = LruEmergencyCache(maxSize: 50);

  List<Map<String, dynamic>> unattendedEmergencies = [];
  bool isLoading = false;

    StreamSubscription<List<Map<String, dynamic>>>? _unattendedSub;

    // StreamController para exponer los unattended al UI (emite cache inmediatamente)
    final StreamController<List<Map<String, dynamic>>> _unattendedController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

    Stream<List<Map<String, dynamic>>> get unattendedStream =>
      _unattendedController.stream;

  /// Key generada por Firebase (push id) para la emergencia creada.
  String? lastEmergencyDbKey;

  // Marca interna para medir tiempo fuera de la app (aprox. duración de llamada)
  DateTime? _callLaunchedAt;

  // --------- Puntos de encuentro conocidos ---------
  static const map.MapLocation Boho = map.MapLocation(
    latitude: 4.6014,
    longitude: -74.0660,
    name: 'Boho',
    description: 'Punto de encuentro',
  );
  static const map.MapLocation ML_banderas = map.MapLocation(
    latitude: 4.603164,
    longitude: -74.065204,
    name: 'ML Banderas',
    description: 'Punto de encuentro',
  );
  static const map.MapLocation sd_cerca = map.MapLocation(
    latitude: 4.603966,
    longitude: -74.065778,
    name: 'SD Cerca',
    description: 'Punto de encuentro',
  );
  static const List<map.MapLocation> _poi = [Boho, ML_banderas, sd_cerca];

  // ---------- Public API ----------

  /// Crea una emergencia en memoria y la persiste en la DB.
  /// Devuelve la Emergency creada (con id en memoria) o null en fallo.
  Future<Emergency?> createEmergencyAndPersist({
    required String userId,
    required LocationEnum location,
    required int secondsResponse,
    EmergencyType type = EmergencyType.Medical,
    String? assignedBrigadistId,
    double? latitude,
    double? longitude,
    EmergencyStatus status = EmergencyStatus.Unattended,
  }) async {
    _isWorking = true;
    notifyListeners();
    try {
      final em = _buildEmergency(
        userId: userId,
        location: location,
        secondsResponse: secondsResponse,
        type: type,
        assignedBrigadistId: assignedBrigadistId,
        status: status,
        latitude: latitude,
        longitude: longitude,
      );
      lastEmergency = em;

      // Persistir
      final key = await _adapter.createEmergencyFromModel(em);
      lastEmergencyDbKey = key;

      onEmergencyCreated?.call(em);
      notifyListeners();
      return em;
    } catch (e) {
      debugPrint('❌ createEmergencyAndPersist error: $e');
      return null;
    } finally {
      _isWorking = false;
      notifyListeners();
    }
  }

  /// Crea y persiste una emergency usando la ubicación actual del dispositivo.
  /// No abre el dialer. Útil para reportes rápidos.
  Future<Emergency?> createEmergencyAtCurrentLocation({
    String? userId,
    required EmergencyType type,
    String? description,
  }) async {
    try {
      final pos = await _getCurrentPosition();

      lastLatitude = pos.latitude;
      lastLongitude = pos.longitude;
      lastLocationAt = DateTime.now();
      onLocationSaved?.call(lastLatitude!, lastLongitude!, lastLocationAt!);

      final locationEnum =
      _inferLocationEnumFromLatLng(pos.latitude, pos.longitude);

      final em = await createEmergencyAndPersist(
        userId: userId ?? currentUserId ?? 'unknown',
        location: locationEnum,
        secondsResponse: 0,
        type: type,
        latitude: pos.latitude,
        longitude: pos.longitude,
        status: EmergencyStatus.Unattended,
      );

      return em;
    } catch (e) {
      debugPrint('❌ createEmergencyAtCurrentLocation error: $e');
      return null;
    }
  }

  /// Llamar a brigadista (simple): abre el dialer y luego persiste una emergencia
  /// usando `persistEmergencyUsingOffline`.
  Future<void> callBrigadist(String phoneNumber, String? userId,) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    lastDialedPhone = phoneNumber;

    if (!await canLaunchUrl(uri)) {
      throw Exception('No se pudo iniciar la llamada');
    }

    _isCalling = true;
    _callLaunchedAt = DateTime.now();
    lastCallDurationSeconds = null;
    notifyListeners();

    await launchUrl(uri, mode: LaunchMode.externalApplication);

    // Guardar emergencia (sin ETA real, usando random / routeCalcTime opcional)
    await persistEmergencyUsingOffline(
      type: EmergencyType.Medical,
      userId: userId,
    );
  }

  /// Guarda una Emergency calculando la ubicación actual y un ETA de ruta.
  /// Esto se puede usar tanto online como "offline" (en cola).
  Future<Emergency?> persistEmergencyUsingOffline({
    required EmergencyType type,
    Duration? routeCalcTime,
    String? userId,
    String? assignedBrigadistId,
  }) async {
    try {
      _isWorking = true;
      notifyListeners();

      // 1) Ubicación actual
      final pos = await _getCurrentPosition();
      lastLatitude = pos.latitude;
      lastLongitude = pos.longitude;
      lastLocationAt = DateTime.now();
      onLocationSaved?.call(lastLatitude!, lastLongitude!, lastLocationAt!);

      // 2) ETA en segundos
      // Si no se pasa routeCalcTime, se genera un valor aleatorio entre 30 y 600 segundos
      final secs = routeCalcTime == null
          ? (math.Random().nextInt(571) + 30) // 30..600
          : (routeCalcTime.inMilliseconds / 1000).ceil();

      // 3) Tipo ya viene como enum
      final emType = type;

      // 4) Inferir ubicación simbólica
      final locEnum =
      _inferLocationEnumFromLatLng(lastLatitude!, lastLongitude!);

      // 5) Construir y persistir
      lastEmergency = _buildEmergency(
        userId: userId ?? currentUserId ?? 'U000',
        location: locEnum,
        secondsResponse: secs,
        type: emType,
        assignedBrigadistId: "",
        status: EmergencyStatus.Unattended,
        latitude: lastLatitude,
        longitude: lastLongitude,
      );

      final key = await _adapter.createEmergencyFromModel(lastEmergency!);
      lastEmergencyDbKey = key;

      onEmergencyCreated?.call(lastEmergency!);
      notifyListeners();
      return lastEmergency;
    } catch (e) {
      debugPrint('❌ persistEmergencyUsingOffline error: $e');
      return null;
    } finally {
      _isWorking = false;
      notifyListeners();
    }
  }

  /// Lógica que combina:
  /// - obtiene la posición actual,
  /// - construye Emergency (usando routeCalcTime provisto por MapVM),
  /// - persiste
  /// - abre el dialer al brigadista.
  Future<void> callBrigadistWithLocation(
      String phoneNumber, {
        required Duration routeCalcTime, // viene desde MapVM.calculateRouteToBrigadist
        String? userId,
      }) async {
    try {
      _isWorking = true;
      notifyListeners();

      // 1) Ubicación actual
      final pos = await _getCurrentPosition();
      lastLatitude = pos.latitude;
      lastLongitude = pos.longitude;
      lastLocationAt = DateTime.now();
      onLocationSaved?.call(lastLatitude!, lastLongitude!, lastLocationAt!);

      // 2) secondsResponse = duración de cálculo de ruta (en segundos, redondeo hacia arriba)
      final initialSecondsResponse =
      (routeCalcTime.inMilliseconds / 1000).ceil();

      // 3) Inferir location y construir Emergency
      final locationEnum =
      _inferLocationEnumFromLatLng(lastLatitude!, lastLongitude!);

      lastEmergency = _buildEmergency(
        userId: userId ?? currentUserId ?? 'U000',
        location: locationEnum,
        secondsResponse: initialSecondsResponse,
        type: EmergencyType.Medical,
        status: EmergencyStatus.Unattended,
        latitude: lastLatitude,
        longitude: lastLongitude,
      );

      // 4) Guardar en Firebase ANTES de abrir el dialer
      await _saveEmergencyIfNeeded();

      onEmergencyCreated?.call(lastEmergency!);

      // 5) Abrir dialer
      await _callPhone(phoneNumber);
    } finally {
      _isWorking = false;
      notifyListeners();
    }
  }

  /// Establece el brigadista asignado (por ejemplo, cuando Orchestrator decide)
  void setAssignedBrigadist(Brigadist b) {
    lastEmergency =
        lastEmergency?.copyWith(assignedBrigadistId: b.studentId) ??
            lastEmergency;
    notifyListeners();
  }

  /// Actualiza secondsResponse y persiste en DB si hay key.
  /// También actualiza `updatedAt` (epoch ms).
  Future<void> updateSecondsResponse(int secs) async {
    if (lastEmergency == null) return;
    lastEmergency = lastEmergency!.copyWith(secondsResponse: secs);
    onEmergencyUpdated?.call(lastEmergency!);

    // Fallback: si no hay key en memoria, intenta hallar la emergencia más reciente del usuario
    if ((lastEmergencyDbKey == null || lastEmergencyDbKey!.isEmpty) &&
        lastEmergency != null) {
      try {
        final all = await _adapter.getEmergencies();
        final uid = lastEmergency!.userId;

        // Ordenar por createdAt si existe, si no por date_time
        all.sort((a, b) {
          final aTs = (a['createdAt'] as num?)?.toInt() ?? 0;
          final bTs = (b['createdAt'] as num?)?.toInt() ?? 0;
          if (aTs != 0 || bTs != 0) return bTs.compareTo(aTs);

          final aDt = DateTime.tryParse(
            (a['date_time'] ?? '') as String? ?? '',
          )
              ?.millisecondsSinceEpoch ??
              0;
          final bDt = DateTime.tryParse(
            (b['date_time'] ?? '') as String? ?? '',
          )
              ?.millisecondsSinceEpoch ??
              0;
          return bDt.compareTo(aDt);
        });

        final mine = all.firstWhere(
              (e) => e['userId']?.toString() == uid,
          orElse: () => {},
        );
        if (mine.isNotEmpty) {
          lastEmergencyDbKey = mine['id']?.toString();
        }
      } catch (e) {
        debugPrint('⚠️ Fallback buscando Emergency por usuario falló: $e');
      }
    }

    if (lastEmergencyDbKey != null && lastEmergencyDbKey!.isNotEmpty) {
      try {
        await _adapter.updateDocument(
          'Emergency',
          lastEmergencyDbKey!,
          {
            'secondsResponse': secs,
            'seconds_response': secs,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          },
        );
      } catch (e) {
        debugPrint('⚠️ updateSecondsResponse failed: $e');
      }
    }
    notifyListeners();
  }

  /// Actualiza el status de la emergencia (Unattended / In progress / Resolved)
  /// y lo persiste en la DB.
  Future<void> updateEmergencyStatus(EmergencyStatus newStatus) async {
    if (lastEmergency == null || lastEmergencyDbKey == null) return;

    lastEmergency = lastEmergency!.copyWith(
      status: newStatus,
      updatedAt: DateTime.now(),
    );
    onEmergencyUpdated?.call(lastEmergency!);

    try {
      await _adapter.updateDocument(
        'Emergency',
        lastEmergencyDbKey!,
        {
          'status': _statusToWire(newStatus),
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      debugPrint('⚠️ updateEmergencyStatus failed: $e');
    }

    notifyListeners();
  }

  /// Limpia la emergencia en memoria (no borra en DB)
  void clearLastEmergency() {
    lastEmergency = null;
    lastEmergencyDbKey = null;
    notifyListeners();
  }

  /// Inicializa la suscripción a emergencias unattended (llamar desde Home.initState)
  Future<void> initUnattendedStream() async {
    isLoading = true;
    notifyListeners();
    // 1) Mostrar lo que haya en cache (memoria) antes de la red
    // Preferir la cache centralizada del Adapter si existe
    List<Map<String, dynamic>> cached = [];
    try {
      cached = _adapter.getCachedUnattendedEmergencies();
    } catch (_) {
      cached = unattendedCache.getAll();
    }
    if (cached.isNotEmpty) {
      unattendedEmergencies = cached;
      // Emitir inmediatamente para UI offline
      if (!_unattendedController.isClosed) _unattendedController.add(unattendedEmergencies);
      notifyListeners();
    }

    // 2) Suscribirse al stream del Adapter
    _unattendedSub?.cancel();
    _unattendedSub = _adapter.getUnattendedEmergenciesStream().listen(
      (fromNetwork) {
        unattendedCache.clear();
        for (final em in fromNetwork) {
          final id = em['id'] as String? ?? '';
          if (id.isNotEmpty) unattendedCache.put(id, Map<String, dynamic>.from(em));
        }

        unattendedEmergencies = unattendedCache.getAll();
        // Emitir al stream para que Home/UI reciba incluso sin recargar
        if (!_unattendedController.isClosed) _unattendedController.add(unattendedEmergencies);
        notifyListeners();

        // Fire-and-forget: precache reporter profiles for the first 3 emergencies
        // We try to fetch the reporter (by userId or email) and store the map in Hive
        _saveFirst3Reporters(fromNetwork);
      },
      onError: (e, st) {
        debugPrint('Error en stream de unattended: $e\n$st');
      },
    );

    isLoading = false;
    notifyListeners();
  }

  // ---------- Guardado en Firebase (interno) ----------
  Future<void> _saveEmergencyIfNeeded() async {
    if (lastEmergency == null) return;
    if (lastEmergencyDbKey != null && lastEmergencyDbKey!.isNotEmpty) return;

    try {
      final key = await _adapter.createEmergencyFromModel(lastEmergency!);
      lastEmergencyDbKey = key;
    } catch (e) {
      debugPrint('❌ Error guardando Emergency: $e');
      rethrow;
    }
  }

  // ---------- Llamada ----------

  Future<void> _callPhone(String phoneNumber) async {
    if (lastEmergencyDbKey == null) {
      try {
        await _saveEmergencyIfNeeded();
      } catch (e) {
        debugPrint('⚠️ Llamando sin guardar Emergency: $e');
      }
    }

    final uri = Uri(scheme: 'tel', path: phoneNumber);
    lastDialedPhone = phoneNumber;

    if (!await canLaunchUrl(uri)) {
      throw Exception('No se pudo iniciar la llamada');
    }

    _isCalling = true;
    _callLaunchedAt = DateTime.now();
    lastCallDurationSeconds = null;
    notifyListeners();

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed &&
        _isCalling &&
        _callLaunchedAt != null) {
      final ms = DateTime.now().difference(_callLaunchedAt!).inMilliseconds;
      final callSecs = ms > 0 ? (ms / 1000).ceil() : 0;

      lastCallDurationSeconds = callSecs;
      _isCalling = false;
      _callLaunchedAt = null;

      onCallDurationSaved?.call(callSecs);

      // Ya NO actualizamos secondsResponse al volver: se mantiene el ETA calculado
      notifyListeners();
    }
  }

  // ---------- Ubicación ----------
  Future<Position> _getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('El servicio de ubicación está desactivado.');
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) {
        throw Exception('Permiso de ubicación denegado.');
      }
    }
    if (perm == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      throw Exception('Permiso de ubicación denegado permanentemente.');
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );
  }

  Future<void> warmupLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  // ---------- Helpers de negocio ----------

  LocationEnum _inferLocationEnumFromLatLng(double lat, double lng) {
    map.MapLocation nearest = _poi.first;
    double best = _haversine(lat, lng, nearest.latitude, nearest.longitude);

    for (final p in _poi.skip(1)) {
      final d = _haversine(lat, lng, p.latitude, p.longitude);
      if (d < best) {
        best = d;
        nearest = p;
      }
    }

    if (nearest == sd_cerca) return LocationEnum.SD;
    if (nearest == ML_banderas) return LocationEnum.ML;
    return LocationEnum.RGD; // Boho u otros
  }

  Emergency _buildEmergency({
    required String userId,
    required LocationEnum location,
    required int secondsResponse,
    EmergencyType type = EmergencyType.Medical,
    String? assignedBrigadistId,
    EmergencyStatus status = EmergencyStatus.Unattended,
    double? latitude,
    double? longitude,
  }) {
    final now = DateTime.now();

    return Emergency(
      emergencyID: now.millisecondsSinceEpoch % 100000000,
      userId: userId,
      assignedBrigadistId: assignedBrigadistId ?? '',
      dateTime: now,
      emerResquestTime: 0,
      secondsResponse: secondsResponse,
      location: location,
      emerType: type,
      status: status,
      latitude: latitude ?? lastLatitude,
      longitude: longitude ?? lastLongitude,
      createdAt: now,
      updatedAt: now,
      chatMessages: null,
    );
  }

  /// Distancia Haversine en metros
  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  double _deg2rad(double deg) => deg * math.pi / 180.0;

  @override
  void dispose() {
    _unattendedSub?.cancel();
    if (!_unattendedController.isClosed) _unattendedController.close();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Dado lat/lng, retorna un LocationEnum (puedes mejorar la lógica según tus ubicaciones)
  LocationEnum emergencyLocationEnumFromLatLng(double lat, double lng) {
    // Ejemplo simple: puedes personalizar según tus ubicaciones reales
    return LocationEnum.RGD;
  }

  // Helper local para mapear status a texto (igual que en Emergency.toJson)
  String _statusToWire(EmergencyStatus s) {
    switch (s) {
      case EmergencyStatus.Unattended:
        return 'Unattended';
      case EmergencyStatus.InProgress:
        return 'In progress';
      case EmergencyStatus.Resolved:
        return 'Resolved';
    }
  }
}


