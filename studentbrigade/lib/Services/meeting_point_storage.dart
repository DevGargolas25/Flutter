import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Modelo simple de MapLocation (si ya lo tienes en otro archivo,
/// omite esta clase y mantén solo MeetingPointStorage)
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

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'name': name,
        'description': description,
      };

  factory MapLocation.fromJson(Map<String, dynamic> json) => MapLocation(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        name: json['name'] as String,
        description: json['description'] as String?,
      );
}

/// Clase que maneja SharedPreferences para meeting points
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
    if (jsonString == null || jsonString.isEmpty) return [];

    final decoded = jsonDecode(jsonString) as List<dynamic>;
    return decoded
        .map((item) => MapLocation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Elimina la clave (opcional)
  static Future<void> clearMeetingPoints() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
