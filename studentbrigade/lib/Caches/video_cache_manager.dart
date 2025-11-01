import 'dart:convert';
import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import '../Models/videoMod.dart';
import '../LocalStorage/videoLocalStorgae.dart';

class VideoCacheManager {
  // Singleton
  static final VideoCacheManager _instance = VideoCacheManager._internal();
  factory VideoCacheManager() => _instance;
  VideoCacheManager._internal();

  // LocalStorage para thumbnails offline
  final VideoLocalStorage _localStorage = VideoLocalStorage();

  // Cache manager para videos SOLAMENTE
  static final CacheManager _videoCacheManager = CacheManager(
    Config(
      'video_cache',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 50,
      repo: JsonCacheInfoRepository(databaseName: 'video_cache'),
      fileService: HttpFileService(),
    ),
  );

  // Archivo temporal para metadata de videos offline
  File? _offlineMetadataFile;

  /// Inicializa el cache manager
  Future<void> initialize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      _offlineMetadataFile = File(
        '${tempDir.path}/offline_videos_metadata.json',
      );

      // Inicializar también el localStorage para thumbnails
      await _localStorage.initialize();

      print('📹 VideoCacheManager inicializado');
    } catch (e) {
      print('❌ Error inicializando VideoCacheManager: $e');
    }
  }

  /// Cachea un video completo
  Future<File?> cacheVideo(String videoUrl) async {
    try {
      print('📹 Cacheando video: $videoUrl');
      final file = await _videoCacheManager.getSingleFile(videoUrl);
      print('✅ Video cacheado: ${file.path}');
      return file;
    } catch (e) {
      print('❌ Error cacheando video: $e');
      return null;
    }
  }

  /// Guarda un thumbnail PERMANENTEMENTE en LocalStorage
  Future<String?> cacheThumbnail(String thumbnailUrl, String videoId) async {
    try {
      print('🖼️ Guardando thumbnail permanente: $thumbnailUrl');

      // Usar VideoLocalStorage en lugar de cache temporal
      final localPath = await _localStorage.downloadAndSaveThumbnail(
        thumbnailUrl,
        videoId,
      );

      if (localPath != null) {
        print('✅ Thumbnail guardado permanentemente: $localPath');
        return localPath;
      } else {
        print('❌ Error guardando thumbnail');
        return null;
      }
    } catch (e) {
      print('❌ Error cacheando thumbnail: $e');
      return null;
    }
  }

  /// Cachea múltiples videos en background
  Future<void> cacheMultipleVideos(List<VideoMod> videos) async {
    try {
      print('📹 Iniciando cache de ${videos.length} videos...');

      // Cachear solo los primeros 10 videos para no sobrecargar
      final videosToCache = videos.take(10).toList();

      // Cachear videos y thumbnails en paralelo
      final videoFutures = videosToCache.map((video) => cacheVideo(video.url));
      final thumbnailFutures = videosToCache.map(
        (video) => cacheThumbnail(video.thumbnail, video.id),
      );

      await Future.wait([...videoFutures, ...thumbnailFutures]);

      print('✅ Cache de videos y thumbnails completado');
    } catch (e) {
      print('❌ Error en cache múltiple: $e');
    }
  }

  /// Cachea los primeros videos de manera prioritaria e inmediata
  Future<void> cachePriorityVideos(
    List<VideoMod> videos, {
    int count = 2,
  }) async {
    try {
      final priorityVideos = videos.take(count).toList();
      print('⚡ Cacheando ${priorityVideos.length} videos prioritarios...');

      for (final video in priorityVideos) {
        try {
          print('📹 Cacheando prioritario: ${video.title}');
          // Cachear video y thumbnail en paralelo
          await Future.wait([
            cacheVideo(video.url),
            cacheThumbnail(video.thumbnail, video.id),
          ]);
          print('✅ Video prioritario cacheado: ${video.title}');
        } catch (e) {
          print('❌ Error cacheando video prioritario ${video.title}: $e');
        }
      }

      print('✅ Cache prioritario completado');
    } catch (e) {
      print('❌ Error en cache prioritario: $e');
    }
  }

  /// Guarda metadata de TODOS los videos para modo offline
  Future<void> saveOfflineVideosMetadata(List<VideoMod> videos) async {
    try {
      if (_offlineMetadataFile == null) {
        await initialize();
      }

      // TODOS los videos (no limitamos a 2)
      print('💾 Guardando metadata de ${videos.length} videos...');

      // Crear metadata
      final metadataList = videos
          .map(
            (video) => {
              'id': video.id,
              'title': video.title,
              'author': video.author,
              'tags': video.tags,
              'url': video.url,
              'duration': video.duration.inSeconds,
              'views': video.views,
              'publishedAt': video.publishedAt.toIso8601String(),
              'thumbnail': video.thumbnail,
              'description': video.description,
              'likes': video.likes,
            },
          )
          .toList();

      // Guardar en archivo temporal
      await _offlineMetadataFile!.writeAsString(jsonEncode(metadataList));

      // TAMBIÉN guardar thumbnails en localStorage (separado del cache)
      await _localStorage.saveOfflineThumbnails(videos);

      print(
        '💾 Metadata de ${videos.length} videos guardada en cache temporal',
      );

      // Asegurar que los thumbnails de estos videos estén cacheados
      for (final video in videos) {
        await cacheThumbnail(video.thumbnail, video.id);
      }
    } catch (e) {
      print('❌ Error guardando metadata offline: $e');
    }
  }

  /// Obtiene videos offline desde cache temporal
  Future<List<VideoMod>> getOfflineVideos() async {
    try {
      if (_offlineMetadataFile == null) {
        await initialize();
      }

      if (_offlineMetadataFile == null || !_offlineMetadataFile!.existsSync()) {
        print('📱 No hay videos offline en cache');
        return [];
      }

      final metadataJson = await _offlineMetadataFile!.readAsString();
      final metadataList = jsonDecode(metadataJson) as List<dynamic>;

      final videos = metadataList
          .map(
            (json) => VideoMod(
              id: json['id'],
              title: json['title'],
              author: json['author'],
              tags: List<String>.from(json['tags']),
              url: json['url'],
              duration: Duration(seconds: json['duration']),
              views: json['views'],
              publishedAt: DateTime.parse(json['publishedAt']),
              thumbnail: json['thumbnail'],
              description: json['description'] ?? '',
              likes: json['likes'] ?? 0,
            ),
          )
          .toList();

      print('📱 ${videos.length} videos offline cargados desde cache');
      return videos;
    } catch (e) {
      print('❌ Error cargando videos offline: $e');
      return [];
    }
  }

  /// Obtiene SOLO los videos que realmente están cacheados en el dispositivo
  Future<List<VideoMod>> getCachedVideosOnly() async {
    try {
      // Primero obtener todos los videos del metadata
      final allVideos = await getOfflineVideos();
      final cachedVideos = <VideoMod>[];

      print('🔍 Verificando cuáles videos están realmente cacheados...');

      // Verificar uno por uno cuáles están realmente cacheados
      for (final video in allVideos) {
        final isVideoCacheAvailable = await isVideoCached(video.url);
        final isThumbnailCacheAvailable = await isThumbnailCached(
          video.thumbnail,
        );

        if (isVideoCacheAvailable || isThumbnailCacheAvailable) {
          cachedVideos.add(video);
          print('✅ Video cacheado: ${video.title}');
        } else {
          print('❌ Video NO cacheado: ${video.title}');
        }
      }

      print(
        '📱 ${cachedVideos.length} de ${allVideos.length} videos están realmente cacheados',
      );
      return cachedVideos;
    } catch (e) {
      print('❌ Error obteniendo videos cacheados: $e');
      return [];
    }
  }

  /// Verifica si un video está en cache
  Future<bool> isVideoCached(String videoUrl) async {
    try {
      final fileInfo = await _videoCacheManager.getFileFromCache(videoUrl);
      return fileInfo != null && fileInfo.file.existsSync();
    } catch (e) {
      return false;
    }
  }

  /// Verifica si un thumbnail está guardado permanentemente
  Future<bool> isThumbnailCached(String videoId) async {
    try {
      final localPath = await _localStorage.getLocalThumbnailPath(videoId);
      return localPath != null && File(localPath).existsSync();
    } catch (e) {
      return false;
    }
  }

  /// Obtiene un video desde cache (sin descargarlo)
  Future<File?> getCachedVideo(String videoUrl) async {
    try {
      final fileInfo = await _videoCacheManager.getFileFromCache(videoUrl);
      if (fileInfo != null && fileInfo.file.existsSync()) {
        return fileInfo.file;
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo video cacheado: $e');
      return null;
    }
  }

  /// Obtiene un thumbnail desde storage permanente
  Future<File?> getCachedThumbnail(String videoId) async {
    try {
      final localPath = await _localStorage.getLocalThumbnailPath(videoId);
      if (localPath != null && File(localPath).existsSync()) {
        return File(localPath);
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo thumbnail guardado: $e');
      return null;
    }
  }

  /// Limpia todo el cache (videos y thumbnails permanentes)
  Future<void> clearAllCache() async {
    try {
      // Limpiar cache de videos
      await _videoCacheManager.emptyCache();

      // Limpiar thumbnails permanentes
      await _localStorage.clearThumbnails();

      // Limpiar archivo de metadata
      if (_offlineMetadataFile != null && _offlineMetadataFile!.existsSync()) {
        await _offlineMetadataFile!.delete();
      }

      print('🗑️ Todo el cache limpiado');
    } catch (e) {
      print('❌ Error limpiando cache: $e');
    }
  }

  /// Obtiene información del cache
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      int offlineCount = 0;

      if (_offlineMetadataFile != null && _offlineMetadataFile!.existsSync()) {
        final content = await _offlineMetadataFile!.readAsString();
        final metadata = jsonDecode(content) as List<dynamic>;
        offlineCount = metadata.length;
      }

      return {
        'cached_videos_count':
            'Unknown', // CacheManager no expone esto fácilmente
        'cached_thumbnails_count': 'Unknown',
        'offline_videos_count': offlineCount,
        'cache_size': 'Unknown',
      };
    } catch (e) {
      return {
        'cached_videos_count': 0,
        'cached_thumbnails_count': 0,
        'offline_videos_count': 0,
        'cache_size': 'Unknown',
      };
    }
  }
}
