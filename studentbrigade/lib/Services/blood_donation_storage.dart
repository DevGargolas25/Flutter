import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../Models/mapMod.dart';

class BloodDonationStorage {
  static const String _bloodDonationPointsKey = 'blood_donation_points';
  static const String _bloodDonationUrlKey = 'blood_donation_url';
  static const String _defaultUrl = 'https://www.cruzrojacolombiana.org/banco-de-sangre/dona-sangre/';

  /// Guarda los puntos de donación en SharedPreferences
  static Future<void> saveBloodDonationPoints(
    List<MapLocation> centers,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = centers.map((center) => jsonEncode(center.toJson())).toList();
      await prefs.setStringList(_bloodDonationPointsKey, jsonList);
      print('✅ Puntos de donación guardados en SharedPreferences');
    } catch (e) {
      print('❌ Error guardando puntos de donación: $e');
    }
  }

  /// Carga los puntos de donación desde SharedPreferences
  static Future<List<MapLocation>> getBloodDonationPoints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_bloodDonationPointsKey);

      if (jsonList == null || jsonList.isEmpty) {
        return List.from(MapData.bloodDonationCenters);
      }

      return jsonList
          .map((json) => MapLocation.fromJson(jsonDecode(json)))
          .toList();
    } catch (e) {
      print('❌ Error cargando puntos de donación: $e');
      return List.from(MapData.bloodDonationCenters);
    }
  }

  /// Guarda la URL del sitio de donación
  static Future<void> saveDonationUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_bloodDonationUrlKey, url);
      print('✅ URL de donación guardada en SharedPreferences');
    } catch (e) {
      print('❌ Error guardando URL de donación: $e');
    }
  }

  /// Obtiene la URL del sitio de donación
  static Future<String> getDonationUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_bloodDonationUrlKey) ?? _defaultUrl;
    } catch (e) {
      print('❌ Error cargando URL de donación: $e');
      return _defaultUrl;
    }
  }

  /// Inicializa los datos por defecto si no existen
  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Inicializar puntos de donación
      if (!prefs.containsKey(_bloodDonationPointsKey)) {
        await saveBloodDonationPoints(MapData.bloodDonationCenters);
      }

      // Inicializar URL
      if (!prefs.containsKey(_bloodDonationUrlKey)) {
        await saveDonationUrl(_defaultUrl);
      }

      print('✅ BloodDonationStorage inicializado');
    } catch (e) {
      print('❌ Error inicializando BloodDonationStorage: $e');
    }
  }

  /// Limpia los datos almacenados (útil para testing)
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_bloodDonationPointsKey);
      await prefs.remove(_bloodDonationUrlKey);
      print('✅ BloodDonationStorage limpiado');
    } catch (e) {
      print('❌ Error limpiando BloodDonationStorage: $e');
    }
  }
}
