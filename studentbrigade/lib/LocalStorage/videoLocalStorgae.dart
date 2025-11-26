import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
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
  Directory? _thumbnailsDir;

  /// Inicializa el storage de thumbnails
  Future<void> initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _thumbnailsFile = File('${appDir.path}/offline_thumbnails.json');
      _thumbnailsDir = Directory('${appDir.path}/thumbnails');

      // Crear directorio de thumbnails si no existe
      if (!await _thumbnailsDir!.exists()) {
        await _thumbnailsDir!.create(recursive: true);
      }

      print('📱 VideoLocalStorage inicializado: ${_thumbnailsFile!.path}');
      print('📁 Directorio thumbnails: ${_thumbnailsDir!.path}');
    } catch (e) {
      print('❌ Error inicializando VideoLocalStorage: $e');
    }
  }

  /// Descarga y guarda un thumbnail permanentemente
  Future<String?> downloadAndSaveThumbnail(
    String thumbnailUrl,
    String videoId,
  ) async {
    try {
      if (_thumbnailsDir == null) await initialize();

      print('🖼️ Descargando thumbnail: $thumbnailUrl');

      // Descargar imagen
      final response = await http.get(Uri.parse(thumbnailUrl));
      if (response.statusCode != 200) {
        print('❌ Error descargando thumbnail: ${response.statusCode}');
        return null;
      }

      // Crear nombre de archivo único
      final extension = thumbnailUrl.split('.').last.split('?').first;
      final fileName = '${videoId}_thumbnail.$extension';
      final thumbnailFile = File('${_thumbnailsDir!.path}/$fileName');

      // Guardar archivo
      await thumbnailFile.writeAsBytes(response.bodyBytes);
      print('✅ Thumbnail guardado: ${thumbnailFile.path}');

      return thumbnailFile.path;
    } catch (e) {
      print('❌ Error descargando thumbnail: $e');
      return null;
    }
  }

  /// Obtiene la ruta local de un thumbnail guardado
  Future<String?> getLocalThumbnailPath(String videoId) async {
    try {
      if (_thumbnailsDir == null) await initialize();

      // Buscar archivo de thumbnail
      final files = await _thumbnailsDir!.list().toList();
      for (final file in files) {
        if (file.path.contains('${videoId}_thumbnail')) {
          return file.path;
        }
      }
      return null;
    } catch (e) {
      print('❌ Error buscando thumbnail local: $e');
      return null;
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

      // Descargar todos los thumbnails y guardar rutas locales
      final thumbnailData = <Map<String, dynamic>>[];

      for (final video in videos) {
        try {
          // Descargar y guardar thumbnail
          final localPath = await downloadAndSaveThumbnail(
            video.thumbnail,
            video.id,
          );

          thumbnailData.add({
            'id': video.id,
            'title': video.title,
            'thumbnail': video.thumbnail, // URL original
            'localThumbnail': localPath, // Ruta local
            'url': video.url,
            'author': video.author,
            'duration': video.duration.inSeconds,
          });

          print('✅ Thumbnail ${video.id} guardado localmente');
        } catch (e) {
          print('❌ Error guardando thumbnail ${video.id}: $e');
          // Guardar sin thumbnail local
          thumbnailData.add({
            'id': video.id,
            'title': video.title,
            'thumbnail': video.thumbnail,
            'localThumbnail': null,
            'url': video.url,
            'author': video.author,
            'duration': video.duration.inSeconds,
          });
        }
      }

      // Guardar metadata en archivo JSON
      await _thumbnailsFile!.writeAsString(jsonEncode(thumbnailData));

      print('🖼️ VideoLocalStorage: ${videos.length} thumbnails procesados');
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

      // Limpiar archivo JSON
      if (_thumbnailsFile != null && _thumbnailsFile!.existsSync()) {
        await _thumbnailsFile!.delete();
      }

      // Limpiar directorio de thumbnails
      if (_thumbnailsDir != null && await _thumbnailsDir!.exists()) {
        await _thumbnailsDir!.delete(recursive: true);
        await _thumbnailsDir!.create(recursive: true);
      }

      print('🗑️ VideoLocalStorage: Thumbnails limpiados');
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
