import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// =============================
/// CLASES PRINCIPALES
/// =============================

class MapLocation {
  final double latitude;
  final double longitude;
  final String name;
  final String? description;

  const MapLocation({
    required this.latitude,
    required this.longitude,
    required this.name,
    this.description,
  });

  // Convertir a JSON
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'name': name,
    'description': description,
  };

  // Crear desde JSON
  factory MapLocation.fromJson(Map<String, dynamic> json) => MapLocation(
    latitude: json['latitude'],
    longitude: json['longitude'],
    name: json['name'],
    description: json['description'],
  );
}

// CLASE PARA UBICACIÓN DEL USUARIO
class UserLocation {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double accuracy;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.accuracy,
  });
}

// CLASE PARA PUNTOS DE RUTA
class RoutePoint {
  final double latitude;
  final double longitude;

  const RoutePoint({
    required this.latitude,
    required this.longitude,
  });
}

// Enum para los tipos de ruta
enum RouteType {
  meetingPoint, // Ruta a punto de encuentro (mapa normal)
  brigadist, // Ruta al brigadista (emergencia)
}

// Clase para manejar múltiples rutas
class RouteData {
  final List<RoutePoint> points;
  final RouteType type;
  final DateTime calculatedAt;
  final double? estimatedDurationMinutes;

  const RouteData({
    required this.points,
    required this.type,
    required this.calculatedAt,
    this.estimatedDurationMinutes,
  });
}

/// =============================
/// DATOS ESTÁTICOS
/// =============================

class MapData {
  static const MapLocation Boho = MapLocation(
    latitude: 4.6014,
    longitude: -74.0660,
    name: 'Boho',
    description: 'Punto de encuentro',
  );

  static const MapLocation ML_banderas = MapLocation(
    latitude: 4.603164,
    longitude: -74.065204,
    name: 'ML Banderas',
    description: 'Punto de encuentro',
  );

  static const MapLocation sd_cerca = MapLocation(
    latitude: 4.603966,
    longitude: -74.065778,
    name: 'SD Cerca',
    description: 'Punto de encuentro',
  );

  static const MapLocation mockUp = MapLocation(
    latitude: 4.795467,
    longitude: -74.067037,
    name: 'Mockup',
    description: 'Punto de encuentro de prueba',
  );

  static const List<MapLocation> meetingPoints = [
    Boho,
    ML_banderas,
    sd_cerca,
  ];
}

/// =============================
/// STORAGE LOCAL
/// =============================

class MeetingPointStorage {
  static const String _key = 'meeting_points';

  /// Guarda la lista de puntos de encuentro en SharedPreferences
  static Future<void> saveMeetingPoints(List<MapLocation> points) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(points.map((p) => p.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  /// Carga los puntos de encuentro desde SharedPreferences
  static Future<List<MapLocation>> loadMeetingPoints() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key);
    if (jsonString == null) return [];

    final decoded = jsonDecode(jsonString) as List<dynamic>;
    return decoded.map((item) => MapLocation.fromJson(item)).toList();
  }

  /// Limpia el almacenamiento (opcional)
  static Future<void> clearMeetingPoints() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

