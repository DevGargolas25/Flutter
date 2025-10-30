import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../VM/Adapter.dart';

/// Cola simple para encolar actualizaciones cuando no hay Internet
/// y reintentar cuando se recupere la conexión.
class OfflineQueue {
  static const _prefsKey = 'offline_mutations_v1';

  /// Encola una actualización genérica por ruta (requiere docId concreto)
  static Future<void> enqueueUpdate(
    String collectionName,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? <String>[];
    final payload = {
      'type': 'update',
      'collection': collectionName,
      'docId': docId,
      'data': data,
      'ts': DateTime.now().toIso8601String(),
    };
    list.add(jsonEncode(payload));
    await prefs.setStringList(_prefsKey, list);
  }

  /// Encola una actualización de usuario localizada por email (no requiere docId)
  static Future<void> enqueueUserUpdateByEmail(
    String email,
    Map<String, dynamic> data,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? <String>[];
    final payload = {
      'type': 'update_user_by_email',
      'email': email,
      'data': data,
      'ts': DateTime.now().toIso8601String(),
    };
    list.add(jsonEncode(payload));
    await prefs.setStringList(_prefsKey, list);
  }

  /// Intenta despachar todas las mutaciones encoladas.
  /// Devuelve cuántas se aplicaron.
  static Future<int> flush(Adapter adapter) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_prefsKey) ?? <String>[];
    if (list.isEmpty) return 0;

    final remaining = <String>[];
    int applied = 0;

    for (final raw in list) {
      try {
        final obj = jsonDecode(raw) as Map<String, dynamic>;
        final type = obj['type'] as String? ?? 'update';
        if (type == 'update') {
          final collection = obj['collection']?.toString() ?? '';
          final docId = obj['docId']?.toString() ?? '';
          final data = Map<String, dynamic>.from(obj['data'] as Map);
          await adapter.updateDocument(collection, docId, data);
          applied++;
        } else if (type == 'update_user_by_email') {
          final email = obj['email']?.toString() ?? '';
          final data = Map<String, dynamic>.from(obj['data'] as Map);
          final ok = await adapter.updateUserByEmail(email, data);
          if (ok) applied++; else remaining.add(raw);
        } else {
          // Tipo desconocido: mantener
          remaining.add(raw);
        }
      } catch (_) {
        // Mantener en la cola si falla (no hay red u otro error)
        remaining.add(raw);
      }
    }

    await prefs.setStringList(_prefsKey, remaining);
    return applied;
  }
}
