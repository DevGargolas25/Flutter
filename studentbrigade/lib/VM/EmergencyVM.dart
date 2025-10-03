// lib/VM/EmergencyVM.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

/// VM para flujo de emergencia:
/// - Llama por teléfono (abre el dialer del sistema).
/// - Obtiene lat/lng actuales (con permisos y GPS activo).
/// - Mide la duración aproximada fuera de la app (proxy de llamada).
/// - Expone hooks para persistencia/analytics.
class EmergencyVM with ChangeNotifier, WidgetsBindingObserver {
  EmergencyVM({this.onLocationSaved, this.onCallDurationSaved}) {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Hooks (opcionales) para que el Orchestrator/DAO persista datos
  final void Function(double lat, double lng, DateTime ts)? onLocationSaved;
  final void Function(int seconds)? onCallDurationSaved;

  // ---------- Estado público para UI ----------
  bool _isWorking = false; // spinner general
  bool get isWorking => _isWorking;

  bool _isCalling = false; // estamos fuera en el dialer (aprox.)
  bool get isCalling => _isCalling;

  String? lastDialedPhone;

  double? lastLatitude;
  double? lastLongitude;
  DateTime? lastLocationAt;

  int? lastCallDurationSeconds; // tiempo aprox. fuera de la app

  // Marcas internas para medición
  DateTime? _callLaunchedAt;

  // ---------- API PRINCIPAL ----------
  /// Obtiene ubicación y luego lanza la llamada.
  /// Si prefieres llamar primero y luego ubicación, invierte el orden.
  Future<void> callBrigadistWithLocation(String phoneNumber) async {
    try {
      _isWorking = true;
      notifyListeners();

      // 1) Ubicación actual (pedirá permisos si hace falta)
      final pos = await _getCurrentPosition();
      lastLatitude = pos.latitude;
      lastLongitude = pos.longitude;
      lastLocationAt = DateTime.now();
      onLocationSaved?.call(lastLatitude!, lastLongitude!, lastLocationAt!);

      // 2) Realizar la llamada (abre el dialer)
      await _callPhone(phoneNumber);
    } finally {
      _isWorking = false;
      notifyListeners();
    }
  }

  // ---------- Llamada ----------
  Future<void> _callPhone(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    lastDialedPhone = phoneNumber;

    if (!await canLaunchUrl(uri)) {
      throw Exception('No se pudo iniciar la llamada');
    }

    _isCalling = true;
    _callLaunchedAt = DateTime.now();
    lastCallDurationSeconds = null;
    notifyListeners();

    // Abre la app de Teléfono (tu app pasa a background)
    await launchUrl(uri, mode: LaunchMode.externalApplication);
    // 👆 Importante: NO navegues inmediatamente después desde la UI.
    // Espera a que la app regrese (didChangeAppLifecycleState -> resumed).
  }

  /// Detecta cuando la app vuelve a primer plano tras la llamada
  /// y calcula una duración APROXIMADA (tiempo fuera de la app).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isCalling && _callLaunchedAt != null) {
      final secs = DateTime.now().difference(_callLaunchedAt!).inSeconds;

      lastCallDurationSeconds = secs;
      _isCalling = false;
      _callLaunchedAt = null;

      // Hook para persistir/analytics
      onCallDurationSaved?.call(secs);

      notifyListeners();
    }
  }

  // ---------- Ubicación ----------
  Future<Position> _getCurrentPosition() async {
    // ¿Servicio de ubicación encendido?
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Puedes abrir settings si quieres: await Geolocator.openLocationSettings();
      throw Exception('El servicio de ubicación está desactivado.');
    }

    // Permisos
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

    // Obtener posición con alta precisión (ajusta timeLimit si necesitas)
    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }

  /// (Opcional) Precalienta permisos antes del flujo SOS para evitar diálogos “detrás”.
  Future<void> warmupLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return; // no falles aquí, solo informa si quieres

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  // ---------- Limpieza ----------
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}

