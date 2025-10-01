import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../Models/mapMod.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;

class MapVM extends ChangeNotifier {
  // Estado de ubicación
  UserLocation? _currentUserLocation;
  bool _isLocationLoading = false;
  bool _isLocationEnabled = false;
  String? _locationError;
  
  // Stream para ubicación en vivo
  StreamSubscription<Position>? _positionStreamSubscription;

  // Getters
  UserLocation? get currentUserLocation => _currentUserLocation;
  bool get isLocationLoading => _isLocationLoading;
  bool get isLocationEnabled => _isLocationEnabled;
  String? get locationError => _locationError;

  // OBTENER UBICACIÓN ACTUAL (UNA VEZ)
  Future<UserLocation?> getCurrentLocation() async {
    _isLocationLoading = true;
    _locationError = null;
    notifyListeners();

    try {
      // Verificar permisos
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationError = 'Location services are disabled';
        _isLocationLoading = false;
        notifyListeners();
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _locationError = 'Location permissions are denied';
          _isLocationLoading = false;
          notifyListeners();
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _locationError = 'Location permissions are permanently denied';
        _isLocationLoading = false;
        notifyListeners();
        return null;
      }

      // Obtener posición actual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentUserLocation = UserLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
        accuracy: position.accuracy,
      );

      _isLocationEnabled = true;

    } catch (e) {
      _locationError = 'Error getting location: $e';
    } finally {
      _isLocationLoading = false;
      notifyListeners();
    }

    return _currentUserLocation;
  }

  // INICIAR SEGUIMIENTO DE UBICACIÓN EN VIVO
  void startLocationTracking() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // Actualizar cada 10 metros
    );

    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _currentUserLocation = UserLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          timestamp: DateTime.now(),
          accuracy: position.accuracy,
        );
        
        print('📍 Location updated: ${position.latitude}, ${position.longitude}');
        notifyListeners();
      },
      onError: (error) {
        _locationError = 'Location tracking error: $error';
        notifyListeners();
      },
    );
  }

  // DETENER SEGUIMIENTO DE UBICACIÓN
  void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  // OBTENER PUNTOS DE ENCUENTRO
  List<MapLocation> getMeetingPoints() {
    return MapData.meetingPoints;
  }

  // Punto más cercano
  MapLocation? getClosestMeetingPoint(UserLocation userLocation) {
    final meetingPoints = getMeetingPoints();
    if (meetingPoints.isEmpty) return null;
  
    MapLocation? closest;
    double minDistance = double.infinity;
  
    for (MapLocation point in meetingPoints) {
      double distance = _calculateDistance(
        userLocation.latitude,
        userLocation.longitude,
        point.latitude,
        point.longitude,
      );
  
      if (distance < minDistance) {
        minDistance = distance;
        closest = point;
      }
    }
  
    return closest;
  }
  
  // Calcular distancia
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Radio de la Tierra en metros
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
        
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // ✅ Agregar al final de la clase MapVM, antes del dispose
  List<RoutePoint>? _currentRoute;
  List<RoutePoint>? get currentRoute => _currentRoute;

  // Calcular ruta desde ubicación actual al punto más cercano
  Future<List<RoutePoint>?> calculateRouteToClosestPoint() async {
    if (_currentUserLocation == null) return null;
    
    final closest = getClosestMeetingPoint(_currentUserLocation!);
    if (closest == null) return null;
    
    try {
      final route = await _fetchRouteFromAPI(
        _currentUserLocation!.latitude,
        _currentUserLocation!.longitude,
        closest.latitude,
        closest.longitude,
      );
      
      _currentRoute = route;
      notifyListeners();
      return route;
    } catch (e) {
      print('Error calculating route: $e');
      return null;
    }
  }
  
  // Método privado para llamar API de rutas
  Future<List<RoutePoint>> _fetchRouteFromAPI(
    double startLat, double startLon,
    double endLat, double endLon,
  ) async {
    try {
      // OSRM (Open Source Routing Machine) - gratuito, sin API key
      final String url = 'http://router.project-osrm.org/route/v1/walking'
          '/$startLon,$startLat;$endLon,$endLat?'
          'overview=full&geometries=geojson';
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final coordinates = data['routes'][0]['geometry']['coordinates'] as List;
          
          return coordinates.map<RoutePoint>((coord) {
            return RoutePoint(
              latitude: coord[1].toDouble(),  // lat
              longitude: coord[0].toDouble(), // lon
            );
          }).toList();
        }
      }
      
      print('❌ OSRM API Error: ${response.statusCode}');
      return _fallbackRoute(startLat, startLon, endLat, endLon);
    } catch (e) {
      print('❌ OSRM Network Error: $e');
      return _fallbackRoute(startLat, startLon, endLat, endLon);
    }
  }

  List<RoutePoint> _fallbackRoute(
    double startLat, double startLon,
    double endLat, double endLon,
  ) {
    return [
      RoutePoint(latitude: startLat, longitude: startLon),
      RoutePoint(latitude: endLat, longitude: endLon),
    ];
  }
  
  void clearRoute() {
    _currentRoute = null;
    notifyListeners();
  }

  @override
  void dispose() {
    stopLocationTracking();
    super.dispose();
  }
}

