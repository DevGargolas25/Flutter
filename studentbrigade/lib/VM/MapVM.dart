import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../Models/mapMod.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;

class MapVM extends ChangeNotifier {
  // ==================== ESTADO COMÚN ====================
  // Estado de ubicación (compartido por ambos mapas)
  UserLocation? _currentUserLocation;
  bool _isLocationLoading = false;
  bool _isLocationEnabled = false;
  String? _locationError;
  StreamSubscription<Position>? _positionStreamSubscription;

  // Getters comunes
  UserLocation? get currentUserLocation => _currentUserLocation;
  bool get isLocationLoading => _isLocationLoading;
  bool get isLocationEnabled => _isLocationEnabled;
  String? get locationError => _locationError;

  // ==================== MAPA NORMAL (Puntos de encuentro) ====================
  RouteData? _meetingPointRoute;

  // Getters para mapa normal
  List<RoutePoint>? get meetingPointRoute => _meetingPointRoute?.points;

  // ==================== MAPA DE EMERGENCIA (Brigadista) ====================
  RouteData? _brigadistRoute;
  bool _isCalculatingEmergencyRoute = false;
  String? _emergencyRouteError;
  
  // Datos específicos de emergencia (para analytics y UI)
  Duration? _routeCalculationTime;
  Duration? _estimatedArrivalTime;
  double? _routeDistance;
  DateTime? _routeCalculationStartTime;

  // Getters para mapa de emergencia
  List<RoutePoint>? get brigadistRoute => _brigadistRoute?.points;
  bool get isCalculatingEmergencyRoute => _isCalculatingEmergencyRoute;
  String? get emergencyRouteError => _emergencyRouteError;
  Duration? get routeCalculationTime => _routeCalculationTime; // Para analytics
  Duration? get estimatedArrivalTime => _estimatedArrivalTime; // Para UI
  double? get routeDistance => _routeDistance;

  // ==================== MÉTODOS COMUNES DE UBICACIÓN ====================
  
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

  void stopLocationTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  // ==================== MÉTODOS DEL MAPA NORMAL ====================
  
  List<MapLocation> getMeetingPoints() {
    return MapData.meetingPoints;
  }

  MapLocation? getClosestMeetingPoint(UserLocation userLocation) {
    final meetingPoints = getMeetingPoints();
    if (meetingPoints.isEmpty) return null;
  
    MapLocation? closest;
    double minDistance = double.infinity;
  
    for (MapLocation point in meetingPoints) {
      double distance = _calculateDistanceInMeters(
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

  // Calcular ruta desde ubicación actual al punto más cercano
  Future<List<RoutePoint>?> calculateRouteToClosestPoint() async {
    if (_currentUserLocation == null) return null;
    
    final closest = getClosestMeetingPoint(_currentUserLocation!);
    if (closest == null) return null;
    
    try {
      print('🗺️ Calculando ruta al punto de encuentro más cercano');
      
      final route = await _fetchRouteFromAPI(
        _currentUserLocation!.latitude,
        _currentUserLocation!.longitude,
        closest.latitude,
        closest.longitude,
        routeType: 'foot',
      );
      
      _meetingPointRoute = RouteData(
        points: route,
        type: RouteType.meetingPoint,
        calculatedAt: DateTime.now(),
      );

      notifyListeners();
      return route;
    } catch (e) {
      print('❌ Error calculating route to meeting point: $e');
      return null;
    }
  }

  void clearMeetingPointRoute() {
    _meetingPointRoute = null;
    notifyListeners();
  }

  // ==================== MÉTODOS DEL MAPA DE EMERGENCIA ====================
  
  // Método principal para calcular ruta al brigadista (usado por Orchestrator)
  Future<void> calculateRouteToBrigadist(double brigadistLat, double brigadistLng) async {
    if (_currentUserLocation == null) {
      throw Exception('User location not available');
    }
    
    // Iniciar medición de tiempo
    _routeCalculationStartTime = DateTime.now();
    _isCalculatingEmergencyRoute = true;
    _emergencyRouteError = null;
    _brigadistRoute = null;
    _estimatedArrivalTime = null;
    _routeDistance = null;
    notifyListeners();

    try {
      print('� Calculando ruta de emergencia al brigadista');
      print('   Desde: (${_currentUserLocation!.latitude}, ${_currentUserLocation!.longitude})');
      print('   Hasta: ($brigadistLat, $brigadistLng)');
      
      // Calcular ruta usando API
      await _calculateEmergencyRouteWithAPI(
        _currentUserLocation!.latitude,
        _currentUserLocation!.longitude,
        brigadistLat,
        brigadistLng,
      );
      
    } catch (e) {
      _emergencyRouteError = e.toString();
      print('❌ Error calculando ruta de emergencia: $e');
    } finally {
      // Calcular tiempo que tomó el cálculo
      if (_routeCalculationStartTime != null) {
        _routeCalculationTime = DateTime.now().difference(_routeCalculationStartTime!);
        print('⏱️ Ruta de emergencia calculada en: ${_routeCalculationTime!.inMilliseconds}ms');
      }
      
      _isCalculatingEmergencyRoute = false;
      notifyListeners();
    }
  }

  Future<void> _calculateEmergencyRouteWithAPI(double fromLat, double fromLng, double toLat, double toLng) async {
    try {
      // Intentar con API real primero
      final route = await _fetchRouteFromAPI(fromLat, fromLng, toLat, toLng, routeType: 'foot');
      
      // Si se obtuvo la ruta de la API, extraer información adicional
      if (route.isNotEmpty) {
        _brigadistRoute = RouteData(
          points: route,
          type: RouteType.brigadist,
          calculatedAt: DateTime.now(),
        );
        
        // Calcular distancia total de la ruta
        _routeDistance = _calculateRouteDistance(route);
        
        // Estimar tiempo basado en velocidad promedio de caminata (5 km/h)
        const averageWalkingSpeedKmh = 5.0;
        final estimatedHours = _routeDistance! / averageWalkingSpeedKmh;
        _estimatedArrivalTime = Duration(minutes: (estimatedHours * 60).round());
        
        print('✅ Ruta de emergencia: ${_routeDistance!.toStringAsFixed(2)} km, ${_estimatedArrivalTime!.inMinutes} min');
      } else {
        throw Exception('No route found');
      }
      
    } catch (e) {
      print('⚠️ Error con API, usando cálculo aproximado: $e');
      
      // Fallback: Cálculo aproximado
      await _calculateEmergencyRouteApproximate(fromLat, fromLng, toLat, toLng);
    }
  }

  Future<void> _calculateEmergencyRouteApproximate(double fromLat, double fromLng, double toLat, double toLng) async {
    // Simular delay de cálculo
    await Future.delayed(const Duration(milliseconds: 800));
    
    // Calcular distancia directa (Haversine)
    final distance = _calculateDistanceInKm(fromLat, fromLng, toLat, toLng);
    _routeDistance = distance;
    
    // Estimar tiempo basado en velocidad promedio de caminata (5 km/h)
    const averageWalkingSpeedKmh = 5.0;
    final estimatedHours = distance / averageWalkingSpeedKmh;
    _estimatedArrivalTime = Duration(minutes: (estimatedHours * 60).round());
    
    // Crear ruta simple (línea recta con puntos intermedios)
    final routePoints = _generateStraightLineRoute(fromLat, fromLng, toLat, toLng);
    _brigadistRoute = RouteData(
      points: routePoints,
      type: RouteType.brigadist,
      calculatedAt: DateTime.now(),
    );
    
    print('✅ Ruta aproximada de emergencia: ${distance.toStringAsFixed(2)} km, ${_estimatedArrivalTime!.inMinutes} min');
  }

  void clearBrigadistRoute() {
    _brigadistRoute = null;
    _routeCalculationTime = null;
    _estimatedArrivalTime = null;
    _routeDistance = null;
    _emergencyRouteError = null;
    notifyListeners();
  }

  // Método para analytics de emergencia
  Map<String, dynamic> getEmergencyRouteAnalytics() {
    return {
      'calculation_time_ms': _routeCalculationTime?.inMilliseconds,
      'route_distance_km': _routeDistance,
      'estimated_arrival_minutes': _estimatedArrivalTime?.inMinutes,
      'calculation_timestamp': _routeCalculationStartTime?.toIso8601String(),
    };
  }

  // ==================== MÉTODOS AUXILIARES PRIVADOS ====================
  
  // Calcular distancia en metros (para puntos de encuentro)
  double _calculateDistanceInMeters(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Radio de la Tierra en metros
    
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);
    
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);
        
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  // Calcular distancia en kilómetros (para emergencias)
  double _calculateDistanceInKm(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // Radio de la Tierra en km
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);
    
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLng / 2) * math.sin(dLng / 2);
    
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _calculateRouteDistance(List<RoutePoint> route) {
    if (route.length < 2) return 0.0;
    
    double totalDistance = 0.0;
    for (int i = 0; i < route.length - 1; i++) {
      totalDistance += _calculateDistanceInKm(
        route[i].latitude,
        route[i].longitude,
        route[i + 1].latitude,
        route[i + 1].longitude,
      );
    }
    
    return totalDistance;
  }

  List<RoutePoint> _generateStraightLineRoute(double lat1, double lng1, double lat2, double lng2) {
    const int points = 10; // Número de puntos intermedios
    final List<RoutePoint> route = [];
    
    for (int i = 0; i <= points; i++) {
      final double ratio = i / points;
      final double lat = lat1 + (lat2 - lat1) * ratio;
      final double lng = lng1 + (lng2 - lng1) * ratio;
      route.add(RoutePoint(latitude: lat, longitude: lng));
    }
    
    return route;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  // Método de API compartido pero usado de diferentes formas
  Future<List<RoutePoint>> _fetchRouteFromAPI(
    double startLat, double startLon,
    double endLat, double endLon, {
    String routeType = 'foot',
  }) async {
    try {
      // OSRM (Open Source Routing Machine) - gratuito, sin API key
      final String url = 'http://router.project-osrm.org/route/v1/$routeType'
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
      
      print('OSRM API Error: ${response.statusCode}');
      return _fallbackRoute(startLat, startLon, endLat, endLon);
    } catch (e) {
      print('OSRM Network Error: $e');
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

  // ==================== MÉTODOS DE LIMPIEZA ====================
  
  void clearAllRoutes() {
    clearMeetingPointRoute();
    clearBrigadistRoute();
  }

  // Método legacy para compatibilidad
  void clearRoute() {
    clearAllRoutes();
  }

  @override
  void dispose() {
    stopLocationTracking();
    super.dispose();
  }
}