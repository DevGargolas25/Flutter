
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import '../Models/videoMod.dart';
import '../Models/userMod.dart';

class Adapter {
  late FirebaseDatabase _database;

  // Constructor para configurar la URL de la base de datos
  Adapter() {
    // REEMPLAZA esta URL con la URL real de tu proyecto
    _database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: 'https://brigadist-29309-default-rtdb.firebaseio.com/' // ← TU URL AQUÍ
    );
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

  // Adapter
  Future<User?> getUserByEmail(String email) async {
    // helpers locales (como en VideoMod)
    String s(dynamic v) => v?.toString() ?? '';
    double d(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    final q = await _database
        .ref('User')
        .orderByChild('email')
        .equalTo(email.toLowerCase().trim())
        .limitToFirst(1)
        .get();

    if (!q.exists) return null;

    final data = q.value as Map<dynamic, dynamic>;
    final first = data.entries.first;

    final id = first.key.toString();
    final m = Map<String, dynamic>.from(first.value as Map);

    final type = (s(m['userType']).isEmpty ? 'student' : s(m['userType'])).toLowerCase();

    switch (type) {
      case 'brigadist':
        return Brigadist(
          fullName: s(m['fullName']),
          studentId: s(m['studentId']),
          email: s(m['email']).toLowerCase().trim(),
          phone: s(m['phone']),
          emergencyName1: s(m['emergencyName1']),
          emergencyPhone1: s(m['emergencyPhone1']),
          emergencyName2: m['emergencyName2'] as String?,
          emergencyPhone2: m['emergencyPhone2'] as String?,
          bloodType: s(m['bloodType']),
          doctorName: m['doctorName'] as String?,
          doctorPhone: m['doctorPhone'] as String?,
          insuranceProvider: s(m['insuranceProvider']),
          foodAllergies: m['foodAllergies'] as String?,
          environmentalAllergies: m['environmentalAllergies'] as String?,
          drugAllergies: m['drugAllergies'] as String?,
          severityNotes: m['severityNotes'] as String?,
          dailyMedications: m['dailyMedications'] as String?,
          emergencyMedications: m['emergencyMedications'] as String?,
          vitaminsSupplements: m['vitaminsSupplements'] as String?,
          specialInstructions: m['specialInstructions'] as String?,
          latitude: d(m['latitude']),
          longitude: d(m['longitude']),
          status: s(m['status']).isEmpty ? 'available' : s(m['status']),
          estimatedArrivalMinutes: (m['estimatedArrivalMinutes'] as num?)?.toDouble(),
        );

      case 'analyst':
        return Analyst(
          fullName: s(m['fullName']),
          studentId: s(m['studentId']),
          email: s(m['email']).toLowerCase().trim(),
          phone: s(m['phone']),
          emergencyName1: s(m['emergencyName1']),
          emergencyPhone1: s(m['emergencyPhone1']),
          emergencyName2: m['emergencyName2'] as String?,
          emergencyPhone2: m['emergencyPhone2'] as String?,
          bloodType: s(m['bloodType']),
          doctorName: m['doctorName'] as String?,
          doctorPhone: m['doctorPhone'] as String?,
          insuranceProvider: s(m['insuranceProvider']),
          foodAllergies: m['foodAllergies'] as String?,
          environmentalAllergies: m['environmentalAllergies'] as String?,
          drugAllergies: m['drugAllergies'] as String?,
          severityNotes: m['severityNotes'] as String?,
          dailyMedications: m['dailyMedications'] as String?,
          emergencyMedications: m['emergencyMedications'] as String?,
          vitaminsSupplements: m['vitaminsSupplements'] as String?,
          specialInstructions: m['specialInstructions'] as String?,
        );

      case 'student':
      default:
        return Student(
          fullName: s(m['fullName']),
          studentId: s(m['studentId']),
          email: s(m['email']).toLowerCase().trim(),
          phone: s(m['phone']),
          emergencyName1: s(m['emergencyName1']),
          emergencyPhone1: s(m['emergencyPhone1']),
          emergencyName2: m['emergencyName2'] as String?,
          emergencyPhone2: m['emergencyPhone2'] as String?,
          bloodType: s(m['bloodType']),
          doctorName: m['doctorName'] as String?,
          doctorPhone: m['doctorPhone'] as String?,
          insuranceProvider: s(m['insuranceProvider']),
          foodAllergies: m['foodAllergies'] as String?,
          environmentalAllergies: m['environmentalAllergies'] as String?,
          drugAllergies: m['drugAllergies'] as String?,
          severityNotes: m['severityNotes'] as String?,
          dailyMedications: m['dailyMedications'] as String?,
          emergencyMedications: m['emergencyMedications'] as String?,
          vitaminsSupplements: m['vitaminsSupplements'] as String?,
          specialInstructions: m['specialInstructions'] as String?,
        );
    }
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
              brigadiers.add({
                'id': key,
                ...userData,
              });
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
  
  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      await _database.ref('User/$userId').update({
        ...userData,
        'updatedAt': ServerValue.timestamp,
      });
    } catch (e) {
      print('Error updating user: $e');
      throw Exception('Error al actualizar usuario: $e');
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
      return tags.map((tag) => tag.toString()).where((tag) => tag.isNotEmpty).toList();
    } else if (tags is String) {
      // Si es un string separado por comas: "Training,Safety"
      return tags.split(',')
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
        return data.entries.map((entry) => {
          'id': entry.key,
          ...Map<String, dynamic>.from(entry.value),
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error getting emergencies: $e');
      throw Exception('Error al obtener emergencias: $e');
    }
  }

  Future<void> createEmergency(Map<String, dynamic> emergencyData) async {
    try {
      final newEmergencyRef = _database.ref('Emergency').push();
      await newEmergencyRef.set({
        ...emergencyData,
        'createdAt': ServerValue.timestamp,
      });
    } catch (e) {
      print('Error creating emergency: $e');
      throw Exception('Error al crear emergencia: $e');
    }
  }
  
  // === GENERIC OPERATIONS ===
  Future<List<Map<String, dynamic>>> getCollection(String collectionName) async {
    try {
      final snapshot = await _database.ref(collectionName).get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        return data.entries.map((entry) => {
          'id': entry.key,
          ...Map<String, dynamic>.from(entry.value),
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error getting collection $collectionName: $e');
      throw Exception('Error al obtener colección $collectionName: $e');
    }
  }
  
  Future<String> addDocument(String collectionName, Map<String, dynamic> data) async {
    try {
      final ref = _database.ref(collectionName).push();
      await ref.set({
        ...data,
        'createdAt': ServerValue.timestamp,
      });
      return ref.key!;
    } catch (e) {
      print('Error adding document to $collectionName: $e');
      throw Exception('Error al agregar documento: $e');
    }
  }
  
  Future<void> updateDocument(String collectionName, String docId, Map<String, dynamic> data) async {
    try {
      await _database.ref('$collectionName/$docId').update({
        ...data,
        'updatedAt': ServerValue.timestamp,
      });
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
}