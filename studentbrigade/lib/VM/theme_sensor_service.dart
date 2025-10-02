// lib/VM/theme_sensor_service.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ambient_light/ambient_light.dart';

/// Traduce lux -> ThemeMode con suavizado + histeresis.
/// Funciona en Android; en iOS el paquete usa CoreMotion/cámara en equipos compatibles.
/// (iOS requiere NSCameraUsageDescription en Info.plist; ver nota al final.)
class ThemeSensorService extends ChangeNotifier {
  ThemeSensorService({
    this.darkEnterLux = 10,   // entra a oscuro cuando el promedio <= 10
    this.lightEnterLux = 80,  // vuelve a claro cuando el promedio >= 80
    this.smoothWindow = 5,    // tamaño de ventana para la media móvil
  }) : assert(darkEnterLux < lightEnterLux, 'darkEnterLux debe ser < lightEnterLux');

  final double darkEnterLux;
  final double lightEnterLux;
  final int smoothWindow;

  StreamSubscription<double>? _sub;
  final _buf = <double>[];

  ThemeMode _mode = ThemeMode.system;
  ThemeMode get mode => _mode;

  double? _lastAvgLux;
  double? get lastAvgLux => _lastAvgLux;

  /// Comienza a escuchar el sensor
  void start() {
    _sub?.cancel();
    final sensor = AmbientLight(); // instancia del plugin
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

    // Histeresis: solo cambia cuando cruza umbrales separados
    if (_mode != ThemeMode.dark && avg <= darkEnterLux) {
      _emit(ThemeMode.dark);
    } else if (_mode != ThemeMode.light && avg >= lightEnterLux) {
      _emit(ThemeMode.light);
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


