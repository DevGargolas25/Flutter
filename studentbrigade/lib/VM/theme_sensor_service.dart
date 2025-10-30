// lib/VM/theme_sensor_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ambient_light/ambient_light.dart';
import 'package:studentbrigade/VM/Adapter.dart';

/// Traduce lux -> ThemeMode con suavizado + histeresis.
/// Funciona en Android; en iOS el paquete usa CoreMotion/cámara en equipos compatibles.
/// (iOS requiere NSCameraUsageDescription en Info.plist; ver nota al final.)
class ThemeSensorService extends ChangeNotifier {
  ThemeSensorService({
    this.darkEnterLux = 10,
    this.lightEnterLux = 80,
    this.smoothWindow = 5,
    this.onResponseMeasured,
  }) : assert(darkEnterLux < lightEnterLux, 'darkEnterLux debe ser < lightEnterLux');

  final double darkEnterLux;
  final double lightEnterLux;
  final int smoothWindow;

  /// Callback opcional: tiempo que tardó en cambiar de modo
  void Function(Duration duration, ThemeMode newMode)? onResponseMeasured;

  // Adapter interno (lazy) para persistir eventos en DB
  Adapter? _adapter;
  Future<void> _ensureAdapter() async {
    if (_adapter != null) return;
    try {
      _adapter = Adapter();
    } catch (e) {
      debugPrint('ThemeSensorService: error creando Adapter: $e');
      _adapter = null;
    }
  }

  StreamSubscription<double>? _sub;
  final _buf = <double>[];

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  double? _lastAvgLux;
  double? get lastAvgLux => _lastAvgLux;

  // Métrica de respuesta
  Duration? _lastResponse;
  Duration? get lastResponse => _lastResponse;

  // Estado para medir transición con histeresis
  DateTime? _pendingStart;
  ThemeMode? _pendingTarget; // ThemeMode.dark o ThemeMode.light

  /// Comienza a escuchar el sensor
  void start() {
    _sub?.cancel();
    final sensor = AmbientLight();
    _sub = sensor.ambientLightStream.listen(
      (double lux) => _onLux(lux),
      onError: (_) => _emit(ThemeMode.system),
      cancelOnError: false,
    );
  }

  /// Detiene la escucha
  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  void _onLux(double lux) {
    _buf.add(lux);
    if (_buf.length > smoothWindow) _buf.removeAt(0);
    final avg = _buf.reduce((a, b) => a + b) / _buf.length;
    _lastAvgLux = avg;

    final now = DateTime.now();

    // Detectar dirección y medir tiempo dentro de la banda de histeresis
    if (_mode != ThemeMode.dark) {
      // Entrando hacia oscuro: cuando baja de lightEnterLux empezamos a medir
      if (avg < lightEnterLux && _pendingTarget != ThemeMode.dark) {
        _pendingTarget = ThemeMode.dark;
        _pendingStart = now;
      }
      // Cambio efectivo a oscuro al cruzar darkEnterLux
      if (avg <= darkEnterLux) {
        if (_pendingTarget == ThemeMode.dark && _pendingStart != null) {
          _lastResponse = now.difference(_pendingStart!);
          // Persistir automáticamente el evento de sensor
          () async {
            try {
              await _ensureAdapter();
              if (_adapter != null) {
                // await _adapter!.saveLightSensorEvent(_lastResponse!, ThemeMode.dark);
              }
            } catch (e) {
              debugPrint('ThemeSensorService: error guardando evento dark: $e');
            }
          }();
          onResponseMeasured?.call(_lastResponse!, ThemeMode.dark);
        }
        _pendingTarget = null;
        _pendingStart = null;
        _emit(ThemeMode.dark);
        return;
      }
    }

    if (_mode != ThemeMode.light) {
      // Entrando hacia claro: cuando sube de darkEnterLux empezamos a medir
      if (avg > darkEnterLux && _pendingTarget != ThemeMode.light) {
        _pendingTarget = ThemeMode.light;
        _pendingStart = now;
      }
      // Cambio efectivo a claro al cruzar lightEnterLux
      if (avg >= lightEnterLux) {
        if (_pendingTarget == ThemeMode.light && _pendingStart != null) {
          _lastResponse = now.difference(_pendingStart!);
          // Persistir automáticamente el evento de sensor
          () async {
            try {
              await _ensureAdapter();
              if (_adapter != null) {
                // await _adapter!.saveLightSensorEvent(_lastResponse!, ThemeMode.light);
              }
            } catch (e) {
              debugPrint('ThemeSensorService: error guardando evento light: $e');
            }
          }();
          onResponseMeasured?.call(_lastResponse!, ThemeMode.light);
        }
        _pendingTarget = null;
        _pendingStart = null;
        _emit(ThemeMode.light);
        return;
      }
    }
  }

  void _emit(ThemeMode m) {
    if (_mode == m) return;
    _mode = m;
    notifyListeners();
  }

  /// Para pruebas en emulador/PC: simula lux sin hardware
  void debugSetLux(double lux) => _onLux(lux);

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
