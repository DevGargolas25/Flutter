import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/mapMod.dart';

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
