import '../VM/Adapter.dart';

class NewsModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String author;
  final DateTime createdAt;
  final List<String> tags;

  const NewsModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.author,
    required this.createdAt,
    required this.tags,
  });

  /// Factory para crear NewsModel desde Firebase
  factory NewsModel.fromFirebase(String key, Map<String, dynamic> json) {
    print('🔄 NewsModel.fromFirebase: key=$key');
    print('🔄 NewsModel.fromFirebase: json=$json');

    try {
      final tags = json['tags'] != null
          ? (json['tags'] is Map
                ? List<String>.from(json['tags'].values)
                : List<String>.from(json['tags'] as List))
          : <String>[];

      print('🔄 NewsModel.fromFirebase: tags parsed=$tags');

      final newsModel = NewsModel(
        id: key,
        title: json['title'] ?? 'Sin título',
        description: json['description'] ?? 'Sin descripción',
        imageUrl: json['imageUrl'] ?? '',
        author: json['author'] ?? 'Autor desconocido',
        createdAt: json['createdAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
            : DateTime.now(),
        tags: tags,
      );

      print('✅ NewsModel.fromFirebase: Modelo creado exitosamente');
      return newsModel;
    } catch (e) {
      print('❌ NewsModel.fromFirebase: Error creando modelo: $e');
      rethrow;
    }
  }

  /// Convierte el modelo a Map para Firebase
  Map<String, dynamic> toFirebase() {
    final tagsMap = <String, String>{};
    for (int i = 0; i < tags.length; i++) {
      tagsMap[i.toString()] = tags[i];
    }

    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'author': author,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'tags': tagsMap,
    };
  }

  /// Crea un NewsModel con datos actualizados
  NewsModel copyWith({
    String? id,
    String? title,
    String? description,
    String? imageUrl,
    String? author,
    DateTime? createdAt,
    List<String>? tags,
  }) {
    return NewsModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      author: author ?? this.author,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
    );
  }

  @override
  String toString() {
    return 'NewsModel(id: $id, title: $title, author: $author, tags: ${tags.length})';
  }
}

/// Servicio para obtener noticias desde Firebase
class NewsService {
  final Adapter _adapter = Adapter();

  /// Obtiene una lista de noticias desde Firebase
  Future<List<NewsModel>> fetchNews({int page = 1, int perPage = 20}) async {
    try {
      print('🗞️ Obteniendo noticias de Firebase...');

      final newsData = await _adapter.getNews();

      print('✅ ${newsData.length} noticias obtenidas de Firebase');
      return newsData;
    } catch (e) {
      print('❌ Error obteniendo noticias: $e');
      return [];
    }
  }

  /// Busca noticias por término
  Future<List<NewsModel>> searchNews(String query) async {
    try {
      print('🔍 Buscando noticias con: "$query"');

      final allNews = await fetchNews();
      final lowercaseQuery = query.toLowerCase();

      final filteredNews = allNews.where((news) {
        return news.title.toLowerCase().contains(lowercaseQuery) ||
            news.description.toLowerCase().contains(lowercaseQuery) ||
            news.author.toLowerCase().contains(lowercaseQuery) ||
            news.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
      }).toList();

      print('✅ ${filteredNews.length} noticias encontradas');
      return filteredNews;
    } catch (e) {
      print('❌ Error buscando noticias: $e');
      return [];
    }
  }

  /// Obtiene una noticia específica por ID
  Future<NewsModel?> getNewsById(String id) async {
    try {
      final allNews = await fetchNews();
      return allNews.firstWhere((news) => news.id == id);
    } catch (e) {
      print('❌ Error obteniendo noticia por ID: $e');
      return null;
    }
  }

  /// Agrega una nueva noticia (para admin)
  Future<bool> addNews(NewsModel news) async {
    try {
      await _adapter.addNews(news);
      return true;
    } catch (e) {
      print('❌ Error agregando noticia: $e');
      return false;
    }
  }
}
