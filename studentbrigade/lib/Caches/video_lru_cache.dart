import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/videoMod.dart';
import '../cache/lru.dart';

/// Cache LRU especializado para videos de carga rápida
class VideoLRUCache {
  static const int _maxVideoCapacity = 3; // Máximo 3 videos más usados
  static const String _lruPersistKey = 'video_lru_cache';

  final LruCache<String, VideoMod> _lruCache = LruCache<String, VideoMod>(
    _maxVideoCapacity,
  );

  static VideoLRUCache? _instance;
  static VideoLRUCache get instance => _instance ??= VideoLRUCache._();

  VideoLRUCache._() {
    _loadFromDisk();
  }

  /// Obtiene un video del caché LRU
  VideoMod? get(String videoId) {
    final video = _lruCache.get(videoId);
    if (video != null) {
      debugPrint('⚡ Video LRU Hit: ${video.title}');
      _saveToDisk(); // Persistir cambio de orden
    }
    return video;
  }

  /// Agrega un video al caché LRU
  void put(String videoId, VideoMod video) {
    _lruCache.put(videoId, video);
    debugPrint(
      '📽️ Video LRU Put: ${video.title} (total: ${_lruCache.length}/$_maxVideoCapacity)',
    );
    _saveToDisk();
  }

  /// Obtiene los videos más usados ordenados por uso (más recientes primero)
  List<VideoMod> getMostUsedVideos() {
    final videosList = <VideoMod>[];

    // LinkedHashMap mantiene el orden de inserción (LRU order)
    // Las más recientes están al final, así que iteramos en reversa
    final entries = _lruCache.cache.entries.toList().reversed;

    for (final entry in entries) {
      videosList.add(entry.value);
    }

    debugPrint(
      '🎬 Video LRU: Devolviendo ${videosList.length} videos ordenados por uso',
    );
    return videosList;
  }

  /// Verifica si un video está en el caché
  bool contains(String videoId) {
    return _lruCache.containsKey(videoId);
  }

  /// Obtiene los IDs de videos más usados para precarga
  List<String> getMostUsedVideoIds() {
    return _lruCache.cache.keys.toList();
  }

  /// Limpia todo el caché LRU
  void clear() {
    _lruCache.clear();
    _saveToDisk();
    debugPrint('🗑️ Video LRU Cache limpiado');
  }

  /// Obtiene estadísticas del LRU
  Map<String, dynamic> getStats() {
    final videosList = getMostUsedVideos();
    return {
      'cached_count': _lruCache.length,
      'max_capacity': _maxVideoCapacity,
      'most_used_title': videosList.isNotEmpty ? videosList.first.title : 'N/A',
      'least_used_title': videosList.isNotEmpty ? videosList.last.title : 'N/A',
      'usage_order': videosList.map((v) => v.title).toList(),
    };
  }

  /// Carga el caché desde disco (SharedPreferences)
  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lruData = prefs.getString(_lruPersistKey);

      if (lruData != null) {
        final Map<String, dynamic> data = jsonDecode(lruData);
        final videoMap = data['videos'] as Map<String, dynamic>;

        // Cargar videos en orden LRU
        for (final entry in videoMap.entries) {
          final videoData = entry.value as Map<String, dynamic>;
          final video = VideoMod(
            id: entry.key,
            title: videoData['title'] ?? '',
            author: videoData['author'] ?? '',
            tags: List<String>.from(videoData['tags'] ?? []),
            url: videoData['url'] ?? '',
            duration: Duration(seconds: videoData['duration'] ?? 0),
            views: videoData['views'] ?? 0,
            publishedAt:
                DateTime.tryParse(videoData['publishedAt'] ?? '') ??
                DateTime.now(),
            thumbnail: videoData['thumbnail'] ?? '',
            description: videoData['description'] ?? '',
            likes: videoData['likes'] ?? 0,
          );
          _lruCache.put(entry.key, video);
        }

        debugPrint(
          '📖 Video LRU: Cargados ${_lruCache.length} videos desde disco',
        );
      }
    } catch (e) {
      debugPrint('❌ Error cargando Video LRU desde disco: $e');
    }
  }

  /// Guarda el caché a disco (SharedPreferences)
  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final videoMap = <String, dynamic>{};

      // Guardar videos manteniendo el orden LRU
      for (final entry in _lruCache.cache.entries) {
        videoMap[entry.key] = {
          'title': entry.value.title,
          'author': entry.value.author,
          'tags': entry.value.tags,
          'url': entry.value.url,
          'duration': entry.value.duration.inSeconds,
          'views': entry.value.views,
          'publishedAt': entry.value.publishedAt.toIso8601String(),
          'thumbnail': entry.value.thumbnail,
          'description': entry.value.description,
          'likes': entry.value.likes,
        };
      }

      final data = {
        'videos': videoMap,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await prefs.setString(_lruPersistKey, jsonEncode(data));
      debugPrint('💾 Video LRU: Guardado en disco (${videoMap.length} videos)');
    } catch (e) {
      debugPrint('❌ Error guardando Video LRU a disco: $e');
    }
  }
}
