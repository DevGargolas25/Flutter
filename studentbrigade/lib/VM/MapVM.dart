import 'package:flutter/foundation.dart';
import '../Models/mapMod.dart';

class MapVM extends ChangeNotifier {
  MapLocation _currentLocation = MapData.uniandes;

  MapLocation get currentLocation => _currentLocation;

  MapLocation getUniandesLocation() {
    return MapData.uniandes;
  }

  void updateLocation(double lat, double lng, String name) {
    _currentLocation = MapLocation(
      latitude: lat,
      longitude: lng,
      name: name,
    );
    notifyListeners();
  }
}