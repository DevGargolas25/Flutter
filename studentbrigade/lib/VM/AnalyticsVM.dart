import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'Adapter.dart';

class AnalyticsVM extends ChangeNotifier {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final Adapter _adapter;

  AnalyticsVM(this._adapter);

  // Eventos personalizados para tu app
  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
    if (kDebugMode) print('📊 Analytics: User logged in via $method');
  }

  Future<void> logEmergencyReport(String type, String location) async {
    await _analytics.logEvent(
      name: 'emergency_reported',
      parameters: {
        'emergency_type': type,
        'location': location,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
    if (kDebugMode)
      print('📊 Analytics: Emergency reported - $type at $location');
  }

  Future<void> logVideoView(String videoId, String videoTitle) async {
    await _analytics.logEvent(
      name: 'video_viewed',
      parameters: {'video_id': videoId, 'video_title': videoTitle},
    );
    if (kDebugMode) print('📊 Analytics: Video viewed - $videoTitle');
  }

  // Método para test (úsalo para verificar conexión)
  Future<void> testAnalytics() async {
    await _analytics.logEvent(
      name: 'test_event',
      parameters: {'test_time': DateTime.now().toString()},
    );
    if (kDebugMode) print('📊 Analytics: Test event sent');
  }

  // === EMERGENCY ANALYTICS ===
  Future<Map<String, dynamic>> getEmergencyAnalytics() async {
    try {
      if (kDebugMode)
        print('📊 AnalyticsVM: Obteniendo analytics de emergencias...');

      // Obtener datos desde el Adapter
      final emergencies = await _adapter.getEmergencyAnalytics();

      // Procesar estadísticas de ubicaciones
      Map<String, int> locationCount = {};
      Map<String, int> emergencyTypeCount = {};
      List<int> responseTimes = [];

      for (var emergency in emergencies) {
        // Contar ubicaciones
        String location = emergency['location'] ?? 'Unknown';
        locationCount[location] = (locationCount[location] ?? 0) + 1;

        // Contar tipos de emergencia
        String emerType = emergency['emerType'] ?? 'Unknown';
        emergencyTypeCount[emerType] = (emergencyTypeCount[emerType] ?? 0) + 1;

        // Recopilar tiempos de respuesta
        int responseTime = emergency['seconds_response'] ?? 0;
        if (responseTime > 0) {
          responseTimes.add(responseTime);
        }
      }

      // Calcular promedio de tiempo de respuesta
      double avgTime = 0.0;
      if (responseTimes.isNotEmpty) {
        avgTime = responseTimes.reduce((a, b) => a + b) / responseTimes.length;
      }

      final result = {
        'locationStats': locationCount,
        'emergencyTypeStats': emergencyTypeCount,
        'avgResponseTime': avgTime,
      };

      if (kDebugMode)
        print('📊 AnalyticsVM: Analytics procesados exitosamente');
      return result;
    } catch (e) {
      if (kDebugMode) print('❌ AnalyticsVM: Error obteniendo analytics: $e');
      rethrow;
    }
  }
}

class AnalyticsNavObserver extends NavigatorObserver {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;

  @override
  void didPush(Route route, Route? previousRoute) {
    final name = route.settings.name ?? route.runtimeType.toString();
    analytics.logScreenView(screenName: name);
    if (kDebugMode) print('📊 Analytics: Screen view - $name');
    super.didPush(route, previousRoute);
  }
}
