import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Servicio para manejar las preferencias de tags de noticias usando SharedPreferences
class NewsPreferencesService {
  static const String _preferencesKey = 'news_tag_preferences';

  static NewsPreferencesService? _instance;
  static NewsPreferencesService get instance =>
      _instance ??= NewsPreferencesService._();

  NewsPreferencesService._();

  /// Guarda las preferencias de tags en SharedPreferences
  Future<void> saveTagPreferences(Map<String, bool> preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = jsonEncode(preferences);
      await prefs.setString(_preferencesKey, preferencesJson);
      debugPrint(
        '✅ Preferencias de tags guardadas: ${preferences.length} tags',
      );
    } catch (e) {
      debugPrint('❌ Error guardando preferencias de tags: $e');
    }
  }

  /// Obtiene las preferencias de tags desde SharedPreferences
  Future<Map<String, bool>> getTagPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = prefs.getString(_preferencesKey);

      if (preferencesJson == null) {
        debugPrint('📭 No hay preferencias de tags guardadas');
        return {};
      }

      final preferences = Map<String, bool>.from(jsonDecode(preferencesJson));
      debugPrint(
        '📰 Preferencias de tags cargadas: ${preferences.length} tags',
      );
      return preferences;
    } catch (e) {
      debugPrint('❌ Error obteniendo preferencias de tags: $e');
      return {};
    }
  }

  /// Obtiene solo los tags marcados como favoritos (true)
  Future<List<String>> getPreferredTags() async {
    final preferences = await getTagPreferences();
    return preferences.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();
  }

  /// Actualiza la preferencia de un tag específico
  Future<void> updateTagPreference(String tag, bool isPreferred) async {
    final currentPreferences = await getTagPreferences();
    currentPreferences[tag] = isPreferred;
    await saveTagPreferences(currentPreferences);
  }

  /// Limpia todas las preferencias
  Future<void> clearPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_preferencesKey);
      debugPrint('🗑️ Preferencias de tags limpiadas');
    } catch (e) {
      debugPrint('❌ Error limpiando preferencias de tags: $e');
    }
  }

  /// Establece múltiples tags como preferidos
  Future<void> setPreferredTags(List<String> tags) async {
    final currentPreferences = await getTagPreferences();

    // Marcar todos los tags especificados como preferidos
    for (final tag in tags) {
      currentPreferences[tag] = true;
    }

    await saveTagPreferences(currentPreferences);
  }

  /// Obtiene estadísticas de las preferencias
  Future<Map<String, dynamic>> getPreferencesStats() async {
    final preferences = await getTagPreferences();
    final preferredCount = preferences.values
        .where((value) => value == true)
        .length;
    final totalCount = preferences.length;

    return {
      'total_tags': totalCount,
      'preferred_tags': preferredCount,
      'preferences': preferences,
    };
  }
}
