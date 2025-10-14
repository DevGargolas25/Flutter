import '../VM/Adapter.dart'; // ← Importar tu Adapter

class VideoMod {
  final String id;
  final String title;
  final String author;
  final List<String> tags; // ["Emergency", "Safety"]
  final String url; // url del video
  final Duration duration; // 5:24
  final int views; // 2300
  final DateTime publishedAt; // para "2 weeks ago"
  final String thumbnail;
  final String description;
  final int likes;

  const VideoMod({
    required this.id,
    required this.title,
    required this.author,
    required this.tags,
    required this.url,
    required this.duration,
    required this.views,
    required this.publishedAt,
    required this.thumbnail,
    this.description = '',
    this.likes = 0,
  });
}

class VideosInfo {
  final Adapter _adapter = Adapter(); // ← Usar tu Adapter

  // SUPER SIMPLE: Solo delegar al Adapter
  Future<List<VideoMod>> fetchAll() async {
    try {
      // El Adapter ya devuelve List<VideoMod> listos para usar
      return await _adapter.getVideos();
    } catch (e) {
      print('❌ Error cargando videos: $e');
      return []; // Lista vacía si hay error
    }
  }

  Future<VideoMod?> getById(String id) async {
    try {
      // El Adapter ya devuelve VideoMod? listo para usar
      return await _adapter.getVideoById(id);
    } catch (e) {
      print('❌ Error obteniendo video por ID: $e');
      return null;
    }
  }
}