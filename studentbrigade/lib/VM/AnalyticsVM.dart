import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/widgets.dart';

class AnalyticsNavObserver extends NavigatorObserver {
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  @override
  void didPush(Route route, Route? previousRoute) {
    final name = route.settings.name;
    if (name != null) {
      analytics.logScreenView(screenName: name);
    }
    super.didPush(route, previousRoute);
  }
}
