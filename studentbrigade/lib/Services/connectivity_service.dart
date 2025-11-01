import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum ConnectivityStatus { online, offline, unknown }

class ConnectivityService extends ChangeNotifier {
  // Singleton
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  ConnectivityStatus _status = ConnectivityStatus.unknown;
  bool _hasInternet = true;

  // Getters
  ConnectivityStatus get status => _status;
  bool get hasInternet => _hasInternet;
  bool get isOffline => !_hasInternet;

  /// Inicializa el servicio de conectividad
  Future<void> initialize() async {
    try {
      // Verificar estado inicial
      await _updateConnectionStatus();

      // Escuchar cambios de conectividad
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _onConnectivityChanged,
        onError: (error) {
          print('❌ ConnectivityService: Error en stream: $error');
        },
      );

      print('🌐 ConnectivityService: Inicializado - Estado: $_status');
    } catch (e) {
      print('❌ ConnectivityService: Error inicializando: $e');
      _status = ConnectivityStatus.unknown;
      _hasInternet = true; // Asumir online por defecto en caso de error
    }
  }

  /// Maneja cambios en la conectividad
  void _onConnectivityChanged(List<ConnectivityResult> results) async {
    await _updateConnectionStatus();
    notifyListeners();

    // Log del cambio
    final statusText = _hasInternet ? 'ONLINE' : 'OFFLINE';
    print('🌐 ConnectivityService: Cambio detectado - $statusText');
  }

  /// Actualiza el estado de conexión
  Future<void> _updateConnectionStatus() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();

      // Verificar si hay alguna conexión disponible
      final hasConnection = connectivityResults.any(
        (result) =>
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.ethernet,
      );

      if (hasConnection) {
        // Por ahora, asumir que hay internet si hay conexión física
        _hasInternet = true;
        _status = ConnectivityStatus.online;
        print('🌐 ConnectivityService: Internet detectado (simplificado)');
      } else {
        // No hay conexión física
        _hasInternet = false;
        _status = ConnectivityStatus.offline;
      }
    } catch (e) {
      print('❌ ConnectivityService: Error verificando conectividad: $e');
      _status = ConnectivityStatus.unknown;
      _hasInternet = true; // Asumir online en caso de error
    }
  }

  /// Verifica si realmente hay acceso a internet (no solo conexión WiFi/móvil)
  // Temporalmente comentado para debugging
  /*
  Future<bool> _hasActualInternetConnection() async {
    try {
      // Hacer una petición simple para verificar internet real
      // Podrías usar tu servidor Firebase o Google DNS
      final response = await _connectivity.checkConnectivity();

      // Por simplicidad, asumir que si hay WiFi/móvil hay internet
      // En una implementación más robusta, harías un ping real
      return response.contains(ConnectivityResult.mobile) ||
          response.contains(ConnectivityResult.wifi) ||
          response.contains(ConnectivityResult.ethernet);
    } catch (e) {
      print('❌ ConnectivityService: Error verificando internet real: $e');
      return false;
    }
  }
  */

  /// Fuerza una verificación manual del estado
  Future<void> checkConnectivity() async {
    await _updateConnectionStatus();
    notifyListeners();
  }

  /// Simula pérdida de conexión (para testing)
  void simulateOffline() {
    if (kDebugMode) {
      _hasInternet = false;
      _status = ConnectivityStatus.offline;
      notifyListeners();
      print('🌐 ConnectivityService: Simulando OFFLINE');
    }
  }

  /// Simula recuperación de conexión (para testing)
  void simulateOnline() {
    if (kDebugMode) {
      _hasInternet = true;
      _status = ConnectivityStatus.online;
      notifyListeners();
      print('🌐 ConnectivityService: Simulando ONLINE');
    }
  }

  /// Limpia recursos
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }
}
