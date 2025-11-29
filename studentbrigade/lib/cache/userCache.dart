// lib/cache/userCache.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/userMod.dart';
import 'lru.dart';

String _norm(String e) => e.trim().toLowerCase();
String _k(String email) => 'user_profile_${_norm(email)}';

class UserCache {
  static final UserCache I = UserCache._(LruCache<String, Map<String, dynamic>>(10));
  final LruCache<String, Map<String, dynamic>> _mem;
  UserCache._(this._mem);

  Future<User?> get(String email) async {
    final key = _norm(email);
    final m = _mem.get(key);
    if (m != null) return User.fromMap(m);

    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_k(email));
    if (raw == null) return null;
    // DEBUG: mostrar el JSON crudo leído desde SharedPreferences
    try {
      debugPrint('[UserCache.get] raw=$raw');
    } catch (_) {}
    final map = jsonDecode(raw) as Map<String, dynamic>;
    try {
      debugPrint('[UserCache.get] map keys=${map.keys.toList()}');
    } catch (_) {}
    _mem.put(key, map);
    return User.fromMap(map);
  }

  Future<void> put(User u) async {
    final map = Map<String, dynamic>.from(u.toMap())
      ..putIfAbsent('userType', () => (u is Brigadist) ? 'brigadist' : (u is Analyst) ? 'analyst' : 'student')
      ..['email'] = _norm(u.email);
    final key = _norm(u.email);
    _mem.put(key, map);
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_k(u.email), jsonEncode(map));
  }

  Future<void> invalidate(String email) async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_k(email));
  }
}
