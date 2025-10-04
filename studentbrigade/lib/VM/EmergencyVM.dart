// lib/VM/EmergencyVM.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

// Modelo Emergency
import '../Models/emergencyMod.dart';

// Modelos del mapa (evitar colisiones de nombres)
import '../Models/mapMod.dart' as map;

// Adapter (Firebase RTDB)
import 'Adapter.dart'; // ajusta si tu ruta real es otra

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

  /// Key generada por Firebase (push id) para la emergencia creada.
  String? lastEmergencyDbKey;

  // Marca interna para medir tiempo fuera de la app (aprox. duración de llamada)
  DateTime? _callLaunchedAt;

  // --------- Puntos de encuentro conocidos ---------
  // Quita `const` si tu map.MapLocation no tiene ctor const.
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

  // ---------- API PRINCIPAL ----------
  /// Crea y guarda Emergency usando la duración de cálculo de ruta (routeCalcTime) como secondsResponse
  /// y luego abre el dialer para realizar la llamada.
  Future<void> callBrigadistWithLocation(
      String phoneNumber, {
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

      // 2) secondsResponse = duración de cálculo de ruta (en segundos)
      final initialSecondsResponse = routeCalcTime.inSeconds;

      // 3) Inferir location y construir Emergency
      final locationEnum =
      _inferLocationEnumFromLatLng(lastLatitude!, lastLongitude!);

      lastEmergency = _buildEmergency(
        userId: userId ?? currentUserId ?? 'U000',
        location: locationEnum,
        secondsResponse: initialSecondsResponse,
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

  // ---------- Guardado en Firebase ----------
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
    // Fallback: por si llaman esto sin haber guardado
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

  /// Si NO quieres sobrescribir `secondsResponse` (de la ruta) con la duración de la llamada,
  /// deja comentado el bloque de copyWith + updateDocument.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.resumed &&
        _isCalling &&
        _callLaunchedAt != null) {
      final secs = DateTime.now().difference(_callLaunchedAt!).inSeconds;

      lastCallDurationSeconds = secs;
      _isCalling = false;
      _callLaunchedAt = null;

      onCallDurationSaved?.call(secs);

      // ----- OPCIONAL: si quieres que secondsResponse pase a la duración de llamada, descomenta:
      /*
      if (lastEmergency != null) {
        lastEmergency = lastEmergency!.copyWith(secondsResponse: secs);
        onEmergencyUpdated?.call(lastEmergency!);
      }
      if (lastEmergencyDbKey != null) {
        try {
          await _adapter.updateDocument(
            'Emergency',
            lastEmergencyDbKey!,
            {
              // 👇 usa camelCase consistente con tu Emergency.toJson()
              'secondsResponse': secs,
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            },
          );
        } catch (e) {
          debugPrint('⚠️ No se pudo actualizar secondsResponse: $e');
        }
      }
      */
      // --------------------------------------------------

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
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
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
  }) {
    final now = DateTime.now();
    return Emergency(
      emergencyID: now.millisecondsSinceEpoch % 100000000,
      userId: userId,
      assignedBrigadistId: 'U002',
      dateTime: now,
      emerResquestTime: 0,
      secondsResponse: secondsResponse,
      location: location,
      emerType: EmergencyType.Medical,
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
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

