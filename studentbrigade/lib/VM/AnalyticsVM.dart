import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AnalyticsVM extends ChangeNotifier {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

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
    if (kDebugMode) print('📊 Analytics: Emergency reported - $type at $location');
  }

  Future<void> logVideoView(String videoId, String videoTitle) async {
    await _analytics.logEvent(
      name: 'video_viewed',
      parameters: {
        'video_id': videoId,
        'video_title': videoTitle,
      },
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