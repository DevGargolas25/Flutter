import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import '../Models/videoMod.dart';
import '../Models/userMod.dart';
import 'package:flutter/foundation.dart';

class Adapter {
  late FirebaseDatabase _database;

  // Constructor para configurar la URL de la base de datos
  Adapter() {
    _database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://brigadist-29309-default-rtdb.firebaseio.com/',
    );
  }

  // === Emergency Operation ==
  Future<String> createEmergencyFromModel(Emergency emergency) async {
    try {
      final ref = _database.ref('Emergency').push();
      final data = emergency.toJson();
      print('🆕 Creando Emergency en: ${ref.path}, payload: ' + data.toString());
      await ref.set({
        ...data,
        'createdAt': ServerValue.timestamp,
      });
      print('✅ Emergency creada con key: ${ref.key}');
      return ref.key!;
    } catch (e) {
      print('Error creating emergency from model: $e');
      throw Exception('Error al crear emergencia: $e');
    }
  }


  
  // === USER OPERATIONS ===
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
  Future<User?> getUserByEmail(String email) async {
    try {
      final emailNorm = email.trim().toLowerCase(); // normaliza
      final ref = _database.ref('User');
      final snap = await ref.orderByChild('email').equalTo(emailNorm).get();

      if (!snap.exists) return null;

      // snap.value es un Map<id, objeto>
      if (snap.value is Map) {
        final usersMap = Map<String, dynamic>.from(snap.value as Map);

        // Tomar el primer resultado
        final entry = usersMap.entries.first;
        final userId = entry.key;
        final data = entry.value;

        if (data is Map) {
          final map = Map<String, dynamic>.from(data);
          map['id'] = userId; // añade el id al mapa
          return User.fromMap(map);
        }
      }

      return null;
    } catch (e, st) {
      debugPrint('🔥 getUserByEmail error: $e\n$st');
      return null;
    }
  }

  // Para actualizar datos del usuario en profile_page
  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    await _database.ref('users/$userId').update(userData);
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
            if (userData['userType'] == 'Brigadist') {
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
}
