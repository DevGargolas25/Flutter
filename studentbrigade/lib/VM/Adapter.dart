import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import '../Models/videoMod.dart';
import '../Models/userMod.dart';
import '../Models/emergencyMod.dart';
import '../Models/newsModel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../cache/userCache.dart';
import '../services/offline_queue.dart';
import '../Caches/lruEmergencyCache';

String _norm(String e) => e.trim().toLowerCase();

class Adapter {
  late FirebaseDatabase _database;
  // Cache local para unattended emergencies (LRU)
  static final LruEmergencyCache _unattendedCache = LruEmergencyCache(maxSize: 50);

  // Constructor para configurar la URL de la base de datos
  Adapter() {
    _database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://brigadist-29309-default-rtdb.firebaseio.com/',
    );

    _database.setPersistenceEnabled(true);
    _database.setPersistenceCacheSizeBytes(10 * 1024 * 1024);
    _database.ref('User').keepSynced(true);
    _database.ref('Video').keepSynced(true);
    _database.ref('Emergency').keepSynced(true);
    _database.ref('news').keepSynced(true);
  }

  Future<bool> _isOffline() async {
    final conn = await Connectivity().checkConnectivity();
    // Para depurar:
    print('conn=$conn  type=${conn.runtimeType}');

    // Si es un único enum:
    if (conn is ConnectivityResult) {
      return conn == ConnectivityResult.none;
    }

    // Si es una lista de resultados (algunas plataformas/devices):
    if (conn is List<ConnectivityResult>) {
      // offline solo si *todos* los interfaces reportan none
      return conn.isEmpty || conn.every((r) => r == ConnectivityResult.none);
    }

    // Conservador si algo raro pasa
    return true;
  }

  Future<int> flushOfflineQueue() async {
    return OfflineQueue.flush(this);
  }

  // === Emergency Operation ===
  Future<String> createEmergencyFromModel(Emergency emergency) async {
    try {
      final ref = _database.ref('Emergency').push();
      final data = emergency.toJson();
      print(
        '🆕 Creando Emergency en: ${ref.path}, payload: ' + data.toString(),
      );
      await ref.set({...data, 'createdAt': ServerValue.timestamp});
      print('✅ Emergency creada con key: ${ref.key}');
      return ref.key!;
    } catch (e) {
      print('Error creating emergency from model: $e');
      throw Exception('Error al crear emergencia: $e');
    }
  }

  /// 🔥 Stream en tiempo real SOLO de emergencias con status "Unattended"
Stream<List<Map<String, dynamic>>> getUnattendedEmergenciesStream() {
  final query = _database
      .ref('Emergency')
      .orderByChild('status')
      .equalTo('Unattended');

  // onValue = Stream<DatabaseEvent>
  return query.onValue.map((event) {
    final snapshot = event.snapshot;

    if (!snapshot.exists || snapshot.value == null) {
      // clear cache if empty snapshot? keep previous cache for offline use
      return <Map<String, dynamic>>[];
    }

    final raw = snapshot.value;

    // Normalmente RTDB devuelve Map<key, value>
    if (raw is Map<dynamic, dynamic>) {
      final list = raw.entries.map((entry) {
        final value = entry.value;
        if (value is Map) {
          return {
            'id': entry.key,
            ...Map<String, dynamic>.from(value),
          };
        }
        return {'id': entry.key};
      }).toList();

      // actualizar cache local
      _unattendedCache.clear();
      for (final em in list) {
        final id = em['id'] as String? ?? '';
        if (id.isNotEmpty) _unattendedCache.put(id, Map<String, dynamic>.from(em));
      }

      return list;
    }

    // Por si te devolviera otra cosa (lista, etc.)
    return <Map<String, dynamic>>[];
  });
}

/// 🔥 SOLO emergencias con status "Unattended"
  Future<List<Map<String, dynamic>>> getUnattendedEmergencies() async {
    try {
      // Ajusta 'status' y 'Unattended' si en tu RTDB usan otro nombre o mayúsculas.
      final query = _database
          .ref('Emergency')
          .orderByChild('status')
          .equalTo('Unattended');

      final snapshot = await query.get();

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final data = snapshot.value as Map<dynamic, dynamic>;

      final list = data.entries.map((entry) {
        final value = entry.value;
        if (value is Map) {
          return {
            'id': entry.key,
            ...Map<String, dynamic>.from(value),
          };
        }
        return {'id': entry.key};
      }).toList();

      // guardar en cache LRU para uso rápido (offline)
      _unattendedCache.clear();
      for (final em in list) {
        final id = em['id'] as String? ?? '';
        if (id.isNotEmpty) _unattendedCache.put(id, Map<String, dynamic>.from(em));
      }

      return list;
    } catch (e) {
      print('❌ Error getting unattended emergencies: $e');
      throw Exception('Error al obtener emergencias Unattended: $e');
    }
  }

  /// Devuelve la lista actualmente en cache (sin tocar la red)
  List<Map<String, dynamic>> getCachedUnattendedEmergencies() {
    return _unattendedCache.getAll();
  }


  // Puedes cambiar el status, el brigadista asignado y/o campos extra.
  Future<void> updateEmergency(
      String emergencyId, {
        String? status,
        String? brigadistId,
        Map<String, dynamic>? extraFields,
      }) async {
    try {
      final data = <String, dynamic>{};

      if (status != null) {
        data['status'] = status;
      }
      if (brigadistId != null) {
        data['brigadistId'] = brigadistId;
      }
      if (extraFields != null) {
        data.addAll(extraFields);
      }

      if (data.isEmpty) return; // nada que actualizar

      await _database.ref('Emergency/$emergencyId').update({
        ...data,
        'updatedAt': ServerValue.timestamp,
      });

      print('✅ Emergency $emergencyId updated: $data');
    } catch (e) {
      print('❌ Error updating emergency: $e');
      throw Exception('Error al actualizar emergencia: $e');
    }
  }

  /// 🔥 SOLO emergencias con status "InProgress"
  Future<List<Map<String, dynamic>>> getInProgressEmergencies() async {
    try {
      final query = _database
          .ref('Emergency')
          .orderByChild('status')
          .equalTo('InProgress');

      final snapshot = await query.get();

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final data = snapshot.value as Map<dynamic, dynamic>;

      return data.entries.map((entry) {
        final value = entry.value;
        if (value is Map) {
          return {
            'id': entry.key,
            ...Map<String, dynamic>.from(value),
          };
        }
        // Por si algún nodo no es Map
        return {'id': entry.key};
      }).toList();
    } catch (e) {
      print('❌ Error getting InProgress emergencies: $e');
      throw Exception('Error al obtener emergencias InProgress: $e');
    }
  }



  
  // === USER OPERATIONS ===

  // offline
  Map<String, dynamic> _mapFromSnap(String id, Object? val) {
    if (val is Map) {
      // safe cast to Map<String, dynamic>
      final map = Map<String, dynamic>.from(val.cast<String, dynamic>());
      map['id'] = id;

      // Normalize and ensure we always have both `type` and `userType`.
      // Some records may use one field or the other, or one can be null.
      final rawType = (map['userType'] ?? 'student').toString();
      final normType = rawType.trim().toLowerCase();
      map['type'] = normType;
      // If userType is missing or null, fill it with the normalized type.
      final rawUserType = map['userType'];
      if (rawUserType == null) {
        map['userType'] = normType;
      } else {
        map['userType'] = rawUserType.toString().trim().toLowerCase();
      }

      if (map['email'] is String) map['email'] = _norm(map['email'] as String);
      return map;
    }

    final map = <String, dynamic>{};
    map['id'] = id;
    map['type'] = 'student';
    map['userType'] = 'student';
    return map;
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    final emailNorm = _norm(email);

    // Si estamos offline, intentar devolver desde cache
    if (await _isOffline()) {
      try {
        final cached = await UserCache.I.get(emailNorm);
        if (cached != null) {
          final map = Map<String, dynamic>.from(cached.toMap());
          if (!map.containsKey('id')) map['id'] = map['id'] ?? '';
          return map;
        }
      } catch (e) {
        print('getUserByEmail (cache) error: $e');
      }
      return null;
    }

    try {
      final ref = _database.ref('User');
      final snap = await ref
          .orderByChild('email')
          .equalTo(emailNorm)
          .limitToFirst(1)
          .get()
          .timeout(const Duration(seconds: 4));

      if (!snap.exists || snap.children.isEmpty) return null;

      final child = snap.children.first;
      final result = _mapFromSnap(child.key ?? '', child.value);
      return result;
    } on TimeoutException {
      // Si hay timeout, intentar fallback a cache
      try {
        final cached = await UserCache.I.get(emailNorm);
        return cached?.toMap();
      } catch (e) {
        print('getUserByEmail timeout and cache fallback failed: $e');
        return null;
      }
    } catch (e) {
      print('getUserByEmail error: $e');
      return null;
    }
  }

  /// 1) Lectura rápida (cache) → 2) RTDB con timeout → cache
  Future<User?> getUserFast(
    String email, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final emailNorm = _norm(email);
    // Si no hay conexión, solo usar cache (memoria/disco).
    if (await _isOffline()) {
      try {
        final cached = await UserCache.I.get(emailNorm);
        debugPrint('[Adapter.getUserFast] offline - returning cache for $emailNorm -> ${cached != null}');
        return cached;
      } catch (e) {
        debugPrint('[Adapter.getUserFast] offline - cache read error: $e');
        return null;
      }
    }

    // 2) Hay conexión: consultar RTDB (timeout) y recalentar cache. Si falla, intentar fallback a cache.
    try {
      final snap = await _database
          .ref('User')
          .orderByChild('email')
          .equalTo(emailNorm)
          .limitToFirst(1)
          .get()
          .timeout(timeout);

      if (!snap.exists || snap.children.isEmpty) return null;

      // Si no encontramos en RTDB, caer de regreso a cache por si acaso
      if (!snap.exists || snap.children.isEmpty) {
        final cached = await UserCache.I.get(emailNorm);
        debugPrint('[Adapter.getUserFast] no snap - returning cache fallback for $emailNorm -> ${cached != null}');
        return cached;
      }

      final child = snap.children.first;
      // DEBUG: mostrar el contenido crudo del child obtenido de RTDB
      try {
        debugPrint('[Adapter.getUserFast] raw child.key=${child.key}');
        final rawVal = child.value;
        debugPrint('[Adapter.getUserFast] raw value runtimeType=${rawVal.runtimeType}');
        if (rawVal is Map) {
          debugPrint('[Adapter.getUserFast] raw keys=${rawVal.keys.toList()}');
          try {
            debugPrint('[Adapter.getUserFast] raw userType=${rawVal['userType']}');
            debugPrint('[Adapter.getUserFast] raw type=${rawVal['type']}');
          } catch (e) {
            debugPrint('[Adapter.getUserFast] error reading keys: $e');
          }
        } else {
          debugPrint('[Adapter.getUserFast] raw value (non-Map): $rawVal');
        }
      } catch (e) {
        debugPrint('[Adapter.getUserFast] debug raw error: $e');
      }

      final map = _mapFromSnap(child.key ?? '', child.value);
      try {
        debugPrint('[Adapter.getUserFast] mapped map keys=${map.keys.toList()}');
        debugPrint('[Adapter.getUserFast] mapped userType=${map['userType']} mapped type=${map['type']}');
      } catch (_) {}
      final u = User.fromMap(map);
      if (u != null) {
        await UserCache.I.put(u); // calienta cache
      }
      return u;
    } on TimeoutException {
      debugPrint('[Adapter] getUserFast timeout "$emailNorm"');
      return null;
    } catch (e) {
      debugPrint('[Adapter] getUserFast error "$emailNorm": $e');
      return null;
    }
  }

  /// Guardar/actualizar un user en RTDB y reflejar en caché
  Future<String> upsertUser(User user) async {
    final emailNorm = _norm(user.email);
    final ref = _database.ref('User');

    final existing = await ref
        .orderByChild('email')
        .equalTo(emailNorm)
        .limitToFirst(1)
        .get();
    final payload = _serializeForRtdb(user);

    if (existing.exists && existing.children.isNotEmpty) {
      final key = existing.children.first.key!;
      await ref.child(key).update(payload);
      await UserCache.I.put(user);
      return key;
    } else {
      final newRef = ref.push();
      await newRef.set(payload);
      await UserCache.I.put(user);
      return newRef.key!;
    }
  }

  Map<String, dynamic> _serializeForRtdb(User u) {
    final map = Map<String, dynamic>.from(u.toMap())
      ..['email'] = _norm(u.email);
    if (u is Brigadist) {
      map['type'] = 'brigadist';
      map['latitude'] = u.latitude;
      map['longitude'] = u.longitude;
      map['status'] = u.status;
      map['estimatedArrivalMinutes'] = u.estimatedArrivalMinutes;
    } else if (u is Analyst) {
      map['type'] = 'analyst';
    } else {
      map['type'] = 'student';
    }
    return map;
  }

  /// Patch parcial y refresca caché si tenemos el email
  Future<void> updateUserFields(
    String userKey,
    Map<String, dynamic> patch, {
    String? email,
  }) async {
    if (patch.containsKey('email')) {
      patch['email'] = _norm(patch['email'] as String);
    }

    final offline = await _isOffline();
    if (offline) {
      // 1) Encola para enviar luego
      if (email != null && email.isNotEmpty) {
        await OfflineQueue.enqueueUserUpdateByEmail(email, patch);
      } else {
        await OfflineQueue.enqueueUpdate('User', userKey, patch);
      }

      // 2) Refresca la caché local de inmediato (la UI ve el cambio)
      if (email != null && email.isNotEmpty) {
        final cached = await UserCache.I.get(_norm(email));
        if (cached != null) {
          final merged = Map<String, dynamic>.from(cached.toMap())
            ..addAll(patch);
          final updated = User.fromMap(merged);
          if (updated != null) await UserCache.I.put(updated);
        }
      }
      return; // no intentes tocar RTDB ahora
    }

    // Online: escribe en RTDB y refresca caché
    await _database.ref('User/$userKey').update(patch);

    if (email != null && email.isNotEmpty) {
      final cached = await UserCache.I.get(_norm(email));
      if (cached != null) {
        final merged = Map<String, dynamic>.from(cached.toMap())..addAll(patch);
        final updated = User.fromMap(merged);
        if (updated != null) await UserCache.I.put(updated);
      } else {
        // si no estaba en cache, intenta traerlo rápido y recalentar
        final u = await getUserFast(email);
        if (u != null) await UserCache.I.put(u);
      }
    }
  }

  /// Actualiza el caché local del usuario (sin tocar DB)
  Future<void> cacheUser(User u) async {
    await UserCache.I.put(u);
  }

  Future<bool> updateUserByEmail(
    String email,
    Map<String, dynamic> patch,
  ) async {
    try {
      // si no hay red, no intentes ir a RTDB: encola y sal

      if (await _isOffline()) {
        await OfflineQueue.enqueueUserUpdateByEmail(email, patch);
        // también refresca cache local para que la UI refleje el cambio
        final cached = await UserCache.I.get(_norm(email));
        if (cached != null) {
          final merged = Map<String, dynamic>.from(cached.toMap())
            ..addAll(patch);
          final updated = User.fromMap(merged);
          if (updated != null) await UserCache.I.put(updated);
        }
        return false; // no se escribió online (se encoló)
      }

      final emailNorm = _norm(email);
      if (patch.containsKey('email')) {
        patch['email'] = _norm(patch['email'] as String);
      }

      final ref = _database.ref('User');
      // 🔒 timeout al query
      final snap = await ref
          .orderByChild('email')
          .equalTo(emailNorm)
          .limitToFirst(1)
          .get()
          .timeout(const Duration(seconds: 4));

      if (!snap.exists || snap.children.isEmpty) return false;

      final key = snap.children.first.key!;
      await ref.child(key).update(patch);

      // refresca cache local
      final current = await UserCache.I.get(emailNorm);
      if (current != null) {
        final merged = Map<String, dynamic>.from(current.toMap())
          ..addAll(patch);
        final updated = User.fromMap(merged);
        if (updated != null) await UserCache.I.put(updated);
      }
      return true;
    } on TimeoutException {
      // 👇 si el query tarda, encola y no bloquees la UI
      await OfflineQueue.enqueueUserUpdateByEmail(email, patch);
      return false;
    } catch (e) {
      debugPrint('updateUserByEmail error: $e');
      // ante error de red, encola también
      await OfflineQueue.enqueueUserUpdateByEmail(email, patch);
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUser(String userId) async {
    try {
      final snapshot = await _database.ref('User/$userId').get();
      if (snapshot.exists) {
        return {
          'id': userId,
          ...Map<String, dynamic>.from(snapshot.value as Map),
        };
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      throw Exception('Error al obtener usuario: $e');
    }
  }

  // Función para poder buscar usuario que inicio sesión
  /*
  Future<User?> getUserByEmail(String email) async {
    try {
      final emailNorm = email.trim().toLowerCase(); // normaliza
      print('[Adapter] Buscando usuario con email: $emailNorm');
      final ref = _database.ref('User');
      final snap = await ref.orderByChild('email').equalTo(emailNorm).get();

      if (!snap.exists) {
        print('[Adapter] No existe usuario con ese email');
        return null;
      }

      // snap.value es un Map<id, objeto>
      if (snap.value is Map) {
        final usersMap = Map<String, dynamic>.from(snap.value as Map);
        print('[Adapter] Usuarios encontrados: \\${usersMap.length}');

        // Tomar el primer resultado
        final entry = usersMap.entries.first;
        final userId = entry.key;
        final data = entry.value;

        if (data is Map) {
          final map = Map<String, dynamic>.from(data);
          map['id'] = userId; // añade el id al mapa
          print('[Adapter] Usuario encontrado: \\${map.toString()}');
          return User.fromMap(map);
        } else {
          print('[Adapter] El dato del usuario no es un Map');
        }
      } else {
        print('[Adapter] snap.value no es un Map');
      }

      print('[Adapter] No se encontró usuario válido');
      return null;
    } catch (e, st) {
      debugPrint('🔥 getUserByEmail error: $e\\n$st');
      return null;
    }
  } */

  // Para actualizar datos del usuario en profile_page
  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    await _database.ref('User/$userId').update(userData);
  }

  // === BRIGADIER OPERATIONS ===
  Future<List<Map<String, dynamic>>> getAllBrigadiers() async {
    try {
      print('🚑 Cargando brigadistas (método alternativo)...'); // Debug

      // Cargar todos los usuarios y filtrar localmente
      final snapshot = await _database.ref('User').get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final brigadiers = <Map<String, dynamic>>[];

        data.forEach((key, value) {
          if (value is Map) {
            final userData = Map<String, dynamic>.from(value);
            final ut = userData['userType']?.toString().toLowerCase();
            if (ut == 'brigadist') {
              brigadiers.add({'id': key, ...userData});
            }
          }
        });

        print('✅ ${brigadiers.length} brigadistas encontrados'); // Debug
        return brigadiers;
      }
      print('⚠️ No hay usuarios'); // Debug
      return [];
    } catch (e) {
      print('❌ Error getting brigadiers: $e');
      throw Exception('Error al obtener brigadistas: $e');
    }
  }

  Future<void> createUser(String userId, Map<String, dynamic> userData) async {
    try {
      await _database.ref('User/$userId').set({
        ...userData,
        'createdAt': ServerValue.timestamp,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      print('Error creating user: $e');
      throw Exception('Error al crear usuario: $e');
    }
  }

  // === VIDEO OPERATIONS ===
  Future<List<VideoMod>> getVideos() async {
    try {
      print('🎥 Cargando videos desde Firebase...'); // Debug
      final snapshot = await _database.ref('Video').get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final videos = <VideoMod>[];

        data.forEach((key, value) {
          try {
            if (value is Map) {
              final videoData = Map<String, dynamic>.from(value);

              // Convertir datos de Firebase a VideoMod
              final video = VideoMod(
                id: key.toString(),
                title: videoData['title']?.toString() ?? 'Sin título',
                author: videoData['author']?.toString() ?? 'Autor desconocido',
                tags: _parseTags(videoData['tags']),
                url: videoData['url']?.toString() ?? '',
                duration: _parseDuration(videoData['duration']),
                views: (videoData['views'] as num?)?.toInt() ?? 0,
                publishedAt: _parseDate(videoData['publishedAt']),
                thumbnail: videoData['thumbnail']?.toString() ?? '',
                description: videoData['description']?.toString() ?? '',
                likes: (videoData['like'] as num?)?.toInt() ?? 0,
              );

              videos.add(video);
              print('✅ Video procesado: ${video.title}');
            }
          } catch (e) {
            print('⚠️ Error procesando video $key: $e');
            // Continúa con el siguiente video si uno falla
          }
        });

        // Ordenar por fecha de publicación (más recientes primero)
        videos.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

        print('✅ ${videos.length} videos cargados y convertidos a VideoMod');
        return videos;
      }

      print('⚠️ No hay videos en Firebase');
      return [];
    } catch (e) {
      print('❌ Error getting videos: $e');
      // En lugar de exception, devolver lista vacía para que la app no se rompa
      return [];
    }
  }

  Future<VideoMod?> getVideoById(String id) async {
    try {
      print('🎥 Buscando video por ID: $id');
      final snapshot = await _database.ref('Video/$id').get();

      if (snapshot.exists) {
        final videoData = Map<String, dynamic>.from(snapshot.value as Map);

        final video = VideoMod(
          id: id,
          title: videoData['title']?.toString() ?? 'Sin título',
          author: videoData['author']?.toString() ?? 'Autor desconocido',
          tags: _parseTags(videoData['tags']),
          url: videoData['url']?.toString() ?? '',
          duration: _parseDuration(videoData['duration']),
          views: (videoData['views'] as num?)?.toInt() ?? 0,
          publishedAt: _parseDate(videoData['publishedAt']),
          thumbnail: videoData['thumbnail']?.toString() ?? '',
          description: videoData['description']?.toString() ?? '',
          likes: (videoData['like'] as num?)?.toInt() ?? 0,
        );

        print('✅ Video encontrado y convertido: ${video.title}');
        return video;
      }

      print('⚠️ Video $id no encontrado');
      return null;
    } catch (e) {
      print('❌ Error getting video by ID: $e');
      return null;
    }
  }

  // === MÉTODOS AUXILIARES PARA PARSING (VIDEO)===

  List<String> _parseTags(dynamic tags) {
    if (tags == null) return [];

    if (tags is List) {
      return tags
          .map((tag) => tag.toString())
          .where((tag) => tag.isNotEmpty)
          .toList();
    } else if (tags is String) {
      // Si es un string separado por comas: "Training,Safety"
      return tags
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
    }

    return [];
  }

  Duration _parseDuration(dynamic duration) {
    if (duration == null) return Duration.zero;

    if (duration is String) {
      // Formato: "10:30" (minutos:segundos)
      try {
        final parts = duration.split(':');
        if (parts.length == 2) {
          final minutes = int.parse(parts[0]);
          final seconds = int.parse(parts[1]);
          return Duration(minutes: minutes, seconds: seconds);
        } else if (parts.length == 3) {
          // Formato: "1:10:30" (horas:minutos:segundos)
          final hours = int.parse(parts[0]);
          final minutes = int.parse(parts[1]);
          final seconds = int.parse(parts[2]);
          return Duration(hours: hours, minutes: minutes, seconds: seconds);
        }
      } catch (e) {
        print('⚠️ Error parsing duration string: $duration');
      }
    } else if (duration is num) {
      // Si está en segundos totales
      return Duration(seconds: duration.toInt());
    }

    return Duration.zero;
  }

  DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();

    if (date is String) {
      try {
        return DateTime.parse(date);
      } catch (e) {
        print('⚠️ Error parsing date: $date');
        return DateTime.now();
      }
    } else if (date is num) {
      // Si es timestamp en milliseconds
      try {
        return DateTime.fromMillisecondsSinceEpoch(date.toInt());
      } catch (e) {
        // Quizás está en segundos
        return DateTime.fromMillisecondsSinceEpoch(date.toInt() * 1000);
      }
    }

    return DateTime.now();
  }

  // === EMERGENCY OPERATIONS ===
  Future<List<Map<String, dynamic>>> getEmergencies() async {
    try {
      final snapshot = await _database.ref('Emergency').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data.entries
            .map(
              (entry) => {
                'id': entry.key,
                ...Map<String, dynamic>.from(entry.value),
              },
            )
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting emergencies: $e');
      throw Exception('Error al obtener emergencias: $e');
    }
  }

  // Crea emergency
  Future<String> createEmergency(Map<String, dynamic> data) async {
    final ref = _database.ref('emergencies').push();
    await ref.set(data);
    return ref.key ?? '';
  }



  // === GENERIC OPERATIONS ===
  Future<List<Map<String, dynamic>>> getCollection(
    String collectionName,
  ) async {
    try {
      final snapshot = await _database.ref(collectionName).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data.entries
            .map(
              (entry) => {
                'id': entry.key,
                ...Map<String, dynamic>.from(entry.value),
              },
            )
            .toList();
      }
      return [];
    } catch (e) {
      print('Error getting collection $collectionName: $e');
      throw Exception('Error al obtener colección $collectionName: $e');
    }
  }

  Future<String> addDocument(
    String collectionName,
    Map<String, dynamic> data,
  ) async {
    try {
      final ref = _database.ref(collectionName).push();
      await ref.set({...data, 'createdAt': ServerValue.timestamp});
      return ref.key!;
    } catch (e) {
      print('Error adding document to $collectionName: $e');
      throw Exception('Error al agregar documento: $e');
    }
  }

  /// Guarda un evento de sensor de luz en la colección 'sensor_events'.
  /// Incluye: modo ('dark'|'light'), duración en ms y un timestamp ISO.
  Future<void> saveLightSensorEvent(
    Duration duration,
    ThemeMode mode, {
    String? userId,
  }) async {
    try {
      final data = <String, dynamic>{
        'type': 'light_sensor',
        'mode': mode == ThemeMode.dark ? 'dark' : 'light',
        'duration_ms': duration.inMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
      };
      if (userId != null) data['userId'] = userId;
      await addDocument('sensor_events', data);
      if (kDebugMode) print('✅ Sensor event persisted: $data');
    } catch (e) {
      print('Error saving light sensor event: $e');
      throw Exception('Error saving light sensor event: $e');
    }
  }

  Future<void> updateDocument(
    String collectionName,
    String docId,
    Map<String, dynamic> data,
  ) async {
    try {
      print('✏️ Update en $collectionName/$docId con: ' + data.toString());
      await _database.ref('$collectionName/$docId').update({
        ...data,
        'updatedAt': ServerValue.timestamp,
      });
      print('✅ Update OK en $collectionName/$docId');
    } catch (e) {
      print('Error updating document: $e');
      throw Exception('Error al actualizar documento: $e');
    }
  }

  Future<void> deleteDocument(String collectionName, String docId) async {
    try {
      await _database.ref('$collectionName/$docId').remove();
    } catch (e) {
      print('Error deleting document: $e');
      throw Exception('Error al eliminar documento: $e');
    }
  }

  // Verificar conexión a Firebase
  Future<bool> testConnection() async {
    try {
      await _database.ref('.info/connected').get();
      return true;
    } catch (e) {
      print('Firebase connection test failed: $e');
      return false;
    }
  }

  Future<void> updateLikes(String videoId, int newLikes) async {
    try {
      await _database.ref('Video/$videoId').update({'like': newLikes});
      print('✅ Likes actualizados para el video $videoId');
    } catch (e) {
      print('❌ Error actualizando likes: $e');
      throw Exception('Error al actualizar likes: $e');
    }
  }

  Future<void> updateViews(String videoId, int newViews) async {
    try {
      await _database.ref('Video/$videoId').update({'views': newViews});
      print('✅ Views actualizados para el video $videoId');
    } catch (e) {
      print('❌ Error actualizando views: $e');
      throw Exception('Error al actualizar views: $e');
    }
  }

  // === EMERGENCY ANALYTICS ===
  Future<List<Map<String, dynamic>>> getEmergencyAnalytics() async {
    try {
      print('📊 Cargando datos de emergencias para analytics...');
      final snapshot = await _database.ref('Emergency').get();

      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        final emergencies = <Map<String, dynamic>>[];

        data.forEach((key, value) {
          if (value is Map) {
            final emergencyData = Map<String, dynamic>.from(value);
            emergencyData['id'] = key.toString();
            emergencies.add(emergencyData);
          }
        });

        print('✅ ${emergencies.length} emergencias cargadas para analytics');
        return emergencies;
      }

      print('⚠️ No hay datos de emergencias');
      return [];
    } catch (e) {
      print('❌ Error getting emergency analytics: $e');
      return [];
    }
  }

  // === USER LIKES & VIEWS TRACKING ===

  // Verificar si un usuario ya dio like a un video
  Future<bool> hasUserLikedVideo(String userId, String videoId) async {
    try {
      final snapshot = await _database.ref('UserLikes/$userId/$videoId').get();
      return snapshot.exists;
    } catch (e) {
      print('❌ Error checking user like: $e');
      return false;
    }
  }

  // Registrar que un usuario dio like a un video
  Future<void> addUserLike(String userId, String videoId) async {
    try {
      await _database.ref('UserLikes/$userId/$videoId').set({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'likedAt': DateTime.now().toIso8601String(),
      });
      print('✅ User like registered: $userId -> $videoId');
    } catch (e) {
      print('❌ Error adding user like: $e');
      throw Exception('Error al registrar like: $e');
    }
  }

  // Verificar si un usuario ya vio un video
  Future<bool> hasUserViewedVideo(String userId, String videoId) async {
    try {
      final snapshot = await _database.ref('UserViews/$userId/$videoId').get();
      return snapshot.exists;
    } catch (e) {
      print('❌ Error checking user view: $e');
      return false;
    }
  }

  // Registrar que un usuario vio un video
  Future<void> addUserView(String userId, String videoId) async {
    try {
      await _database.ref('UserViews/$userId/$videoId').set({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'viewedAt': DateTime.now().toIso8601String(),
      });
      print('✅ User view registered: $userId -> $videoId');
    } catch (e) {
      print('❌ Error adding user view: $e');
      throw Exception('Error al registrar view: $e');
    }
  }

  // Actualizar likes solo si el usuario no ha dado like antes
  Future<bool> updateLikesIfNotLiked(String userId, String videoId) async {
    try {
      // Verificar si ya dio like
      final hasLiked = await hasUserLikedVideo(userId, videoId);
      if (hasLiked) {
        print('⚠️ Usuario $userId ya dio like al video $videoId');
        return false; // No se actualizó
      }

      // Obtener likes actuales
      final videoSnapshot = await _database.ref('Video/$videoId/like').get();
      int currentLikes = 0;
      if (videoSnapshot.exists) {
        currentLikes = (videoSnapshot.value as num?)?.toInt() ?? 0;
      }

      // Actualizar likes y registrar usuario
      final newLikes = currentLikes + 1;
      await _database.ref('Video/$videoId/like').set(newLikes);
      await addUserLike(userId, videoId);

      print('✅ Like actualizado: $videoId -> $newLikes');
      return true; // Se actualizó correctamente
    } catch (e) {
      print('❌ Error updating likes: $e');
      throw Exception('Error al actualizar likes: $e');
    }
  }

  // Actualizar views solo si el usuario no ha visto antes
  Future<bool> updateViewsIfNotViewed(String userId, String videoId) async {
    try {
      // Verificar si ya vio el video
      final hasViewed = await hasUserViewedVideo(userId, videoId);
      if (hasViewed) {
        print('⚠️ Usuario $userId ya vio el video $videoId');
        return false; // No se actualizó
      }

      // Obtener views actuales
      final videoSnapshot = await _database.ref('Video/$videoId/views').get();
      int currentViews = 0;
      if (videoSnapshot.exists) {
        currentViews = (videoSnapshot.value as num?)?.toInt() ?? 0;
      }

      // Actualizar views y registrar usuario
      final newViews = currentViews + 1;
      await _database.ref('Video/$videoId/views').set(newViews);
      await addUserView(userId, videoId);

      print('✅ View actualizado: $videoId -> $newViews');
      return true; // Se actualizó correctamente
    } catch (e) {
      print('❌ Error updating views: $e');
      throw Exception('Error al actualizar views: $e');
    }
  }

  // Obtener estado de likes/views para mostrar en UI
  Future<Map<String, bool>> getUserVideoInteractions(
    String userId,
    String videoId,
  ) async {
    try {
      final hasLiked = await hasUserLikedVideo(userId, videoId);
      final hasViewed = await hasUserViewedVideo(userId, videoId);

      return {'hasLiked': hasLiked, 'hasViewed': hasViewed};
    } catch (e) {
      print('❌ Error getting user video interactions: $e');
      return {'hasLiked': false, 'hasViewed': false};
    }
  }

  // ============ NOTICIAS ============

  /// Obtiene todas las noticias desde Firebase
  Future<List<NewsModel>> getNews() async {
    try {
      print('🔥 Adapter: Conectando a Firebase para obtener noticias...');
      final newsRef = _database.ref('news');
      print('🔥 Adapter: Referencia creada: ${newsRef.path}');

      final snapshot = await newsRef.get();
      print('🔥 Adapter: Snapshot obtenido. Exists: ${snapshot.exists}');

      if (snapshot.exists && snapshot.value != null) {
        print('🔥 Adapter: Snapshot value type: ${snapshot.value.runtimeType}');
        print('🔥 Adapter: Snapshot value: ${snapshot.value}');

        final newsMap = snapshot.value as Map<dynamic, dynamic>;
        print('🔥 Adapter: NewsMap keys: ${newsMap.keys.toList()}');

        final List<NewsModel> newsList = [];

        newsMap.forEach((key, value) {
          print(
            '🔥 Adapter: Procesando key: $key, value type: ${value.runtimeType}',
          );

          if (value is Map<dynamic, dynamic>) {
            try {
              final newsItem = Map<String, dynamic>.from(value);
              print('🔥 Adapter: NewsItem: $newsItem');

              final newsModel = NewsModel.fromFirebase(
                key.toString(),
                newsItem,
              );
              newsList.add(newsModel);
              print('✅ Adapter: Noticia agregada: ${newsModel.title}');
            } catch (e) {
              print('❌ Adapter: Error procesando noticia $key: $e');
            }
          }
        });

        // Ordenar por fecha de creación (más reciente primero)
        newsList.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        print('✅ ${newsList.length} noticias obtenidas de Firebase');
        return newsList;
      } else {
        print(
          '⚠️ No hay noticias en Firebase - snapshot.exists: ${snapshot.exists}, value: ${snapshot.value}',
        );
      }

      return [];
    } catch (e) {
      print('❌ Error obteniendo noticias: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Agrega una nueva noticia a Firebase
  Future<void> addNews(NewsModel newsModel) async {
    try {
      final newsRef = _database.ref('news').push();
      final data = newsModel.toFirebase();

      await newsRef.set(data);
      print('✅ Noticia agregada: ${newsModel.title}');
    } catch (e) {
      print('❌ Error agregando noticia: $e');
      throw Exception('Error al agregar noticia: $e');
    }
  }

  /// Actualiza una noticia existente
  Future<void> updateNews(String newsId, NewsModel newsModel) async {
    try {
      final newsRef = _database.ref('news/$newsId');
      final data = newsModel.toFirebase();

      await newsRef.update(data);
      print('✅ Noticia actualizada: $newsId');
    } catch (e) {
      print('❌ Error actualizando noticia: $e');
      throw Exception('Error al actualizar noticia: $e');
    }
  }

  /// Elimina una noticia
  Future<void> deleteNews(String newsId) async {
    try {
      await _database.ref('news/$newsId').remove();
      print('✅ Noticia eliminada: $newsId');
    } catch (e) {
      print('❌ Error eliminando noticia: $e');
      throw Exception('Error al eliminar noticia: $e');
    }
  }
}
