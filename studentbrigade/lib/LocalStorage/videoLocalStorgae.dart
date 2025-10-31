import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../Models/videoMod.dart';

/// LocalStorage para SOLO thumbnails de videos offline
/// NO usar SharedPreferences para videos!
class VideoLocalStorage {
  // Singleton
  static final VideoLocalStorage _instance = VideoLocalStorage._internal();
  factory VideoLocalStorage() => _instance;
  VideoLocalStorage._internal();

  File? _thumbnailsFile;

  /// Inicializa el storage de thumbnails
  Future<void> initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _thumbnailsFile = File('${appDir.path}/offline_thumbnails.json');
      print('📱 VideoLocalStorage inicializado: ${_thumbnailsFile!.path}');
    } catch (e) {
      print('❌ Error inicializando VideoLocalStorage: $e');
    }
  }

  /// Guarda thumbnails de TODOS los videos para modo offline
  Future<void> saveOfflineThumbnails(List<VideoMod> videos) async {
    try {
      if (_thumbnailsFile == null) await initialize();

      // TODOS los videos (no solo 2)
      print('🖼️ VideoLocalStorage: Guardando ${videos.length} thumbnails...');

      // Crear estructura SOLO para thumbnails
      final thumbnailData = videos
          .map(
            (video) => {
              'id': video.id,
              'title': video.title,
              'thumbnail': video.thumbnail,
              'url': video.url, // Para identificar el video
              'author': video.author,
              'duration': video.duration.inSeconds,
            },
          )
          .toList();

      // Guardar en archivo local
      await _thumbnailsFile!.writeAsString(jsonEncode(thumbnailData));

      print(
        '🖼️ VideoLocalStorage: ${videos.length} thumbnails guardados localmente',
      );
    } catch (e) {
      print('❌ VideoLocalStorage: Error guardando thumbnails: $e');
    }
  }

  /// Obtiene thumbnails guardados localmente
  Future<List<Map<String, dynamic>>> getOfflineThumbnails() async {
    try {
      if (_thumbnailsFile == null) await initialize();

      if (_thumbnailsFile == null || !_thumbnailsFile!.existsSync()) {
        print('� VideoLocalStorage: No hay thumbnails guardados');
        return [];
      }

      final content = await _thumbnailsFile!.readAsString();
      final thumbnailList = jsonDecode(content) as List<dynamic>;
      final thumbnails = thumbnailList.cast<Map<String, dynamic>>();

      print('�️ VideoLocalStorage: ${thumbnails.length} thumbnails cargados');
      return thumbnails;
    } catch (e) {
      print('❌ VideoLocalStorage: Error cargando thumbnails: $e');
      return [];
    }
  }

  /// Verifica si hay thumbnails para un video específico
  Future<String?> getThumbnailForVideo(String videoUrl) async {
    try {
      final thumbnails = await getOfflineThumbnails();

      for (final thumb in thumbnails) {
        if (thumb['url'] == videoUrl) {
          return thumb['thumbnail'] as String?;
        }
      }

      return null;
    } catch (e) {
      print('❌ VideoLocalStorage: Error buscando thumbnail: $e');
      return null;
    }
  }

  /// Limpia SOLO los thumbnails locales
  Future<void> clearThumbnails() async {
    try {
      if (_thumbnailsFile == null) await initialize();

      if (_thumbnailsFile != null && _thumbnailsFile!.existsSync()) {
        await _thumbnailsFile!.delete();
        print('�️ VideoLocalStorage: Thumbnails limpiados');
      }
    } catch (e) {
      print('❌ VideoLocalStorage: Error limpiando thumbnails: $e');
    }
  }

  /// Verifica si hay thumbnails guardados
  Future<bool> hasThumbnails() async {
    try {
      if (_thumbnailsFile == null) await initialize();
      return _thumbnailsFile != null && _thumbnailsFile!.existsSync();
    } catch (e) {
      return false;
    }
  }
}
