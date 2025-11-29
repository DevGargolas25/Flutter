import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'newsModel.dart';
import '../cache/lru.dart';

/// Cache LRU especializado para noticias
class NewsLRUCache {
  static const int _maxNewsCapacity = 5; // Máximo 5 noticias en LRU
  static const String _lruPersistKey = 'news_lru_cache';

  final LruCache<String, NewsModel> _lruCache = LruCache<String, NewsModel>(
    _maxNewsCapacity,
  );

  static NewsLRUCache? _instance;
  static NewsLRUCache get instance => _instance ??= NewsLRUCache._();

  NewsLRUCache._() {
    _loadFromDisk();
  }

  /// Obtiene una noticia del caché LRU
  NewsModel? get(String newsId) {
    final news = _lruCache.get(newsId);
    if (news != null) {
      debugPrint('📰 LRU Hit: ${news.title}');
      _saveToDisk(); // Persistir cambio de orden
    }
    return news;
  }

  /// Agrega una noticia al caché LRU
  void put(String newsId, NewsModel news) {
    _lruCache.put(newsId, news);
    debugPrint(
      '📝 LRU Put: ${news.title} (total: ${_lruCache.length}/$_maxNewsCapacity)',
    );
    _saveToDisk();
  }

  /// Obtiene todas las noticias ordenadas por uso (más recientes primero)
  List<NewsModel> getMostUsedNews() {
    final newsList = <NewsModel>[];

    // LinkedHashMap mantiene el orden de inserción (LRU order)
    // Las más recientes están al final, así que iteramos en reversa
    final entries = _lruCache.cache.entries.toList().reversed;

    for (final entry in entries) {
      newsList.add(entry.value);
    }

    debugPrint(
      '📊 LRU: Devolviendo ${newsList.length} noticias ordenadas por uso',
    );
    return newsList;
  }

  /// Verifica si una noticia está en el caché
  bool contains(String newsId) {
    return _lruCache.containsKey(newsId);
  }

  /// Limpia todo el caché LRU
  void clear() {
    _lruCache.clear();
    _saveToDisk();
    debugPrint('🗑️ LRU Cache limpiado');
  }

  /// Obtiene estadísticas del LRU
  Map<String, dynamic> getStats() {
    final newsList = getMostUsedNews();
    return {
      'cached_count': _lruCache.length,
      'max_capacity': _maxNewsCapacity,
      'most_used_title': newsList.isNotEmpty ? newsList.first.title : 'N/A',
      'least_used_title': newsList.isNotEmpty ? newsList.last.title : 'N/A',
      'usage_order': newsList.map((n) => n.title).toList(),
    };
  }

  /// Carga el caché desde disco (SharedPreferences)
  Future<void> _loadFromDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lruData = prefs.getString(_lruPersistKey);

      if (lruData != null) {
        final Map<String, dynamic> data = jsonDecode(lruData);
        final newsMap = data['news'] as Map<String, dynamic>;

        // Cargar noticias en orden LRU
        for (final entry in newsMap.entries) {
          final newsData = entry.value as Map<String, dynamic>;
          final news = NewsModel.fromFirebase(entry.key, newsData);
          _lruCache.put(entry.key, news);
        }

        debugPrint('📖 LRU: Cargadas ${_lruCache.length} noticias desde disco');
      }
    } catch (e) {
      debugPrint('❌ Error cargando LRU desde disco: $e');
    }
  }

  /// Guarda el caché a disco (SharedPreferences)
  Future<void> _saveToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final newsMap = <String, dynamic>{};

      // Guardar noticias manteniendo el orden LRU
      for (final entry in _lruCache.cache.entries) {
        newsMap[entry.key] = entry.value.toFirebase();
      }

      final data = {
        'news': newsMap,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      await prefs.setString(_lruPersistKey, jsonEncode(data));
      debugPrint('💾 LRU: Guardado en disco (${newsMap.length} noticias)');
    } catch (e) {
      debugPrint('❌ Error guardando LRU a disco: $e');
    }
  }
}

/// Cache Manager especializado para noticias con LRU
class NewsCacheManager {
  static const String _newsCacheKey = 'cached_news';
  static const Duration _cacheExpiry = Duration(hours: 24);

  static NewsCacheManager? _instance;
  static NewsCacheManager get instance => _instance ??= NewsCacheManager._();

  final CacheManager _cacheManager = DefaultCacheManager();
  final NewsLRUCache _lruCache = NewsLRUCache.instance;

  NewsCacheManager._();

  /// Guarda noticias en caché local con timestamp
  Future<void> cacheNews(List<NewsModel> news) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final cacheData = {
        'news': news.map((n) => n.toFirebase()).toList(),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'count': news.length,
      };

      await prefs.setString(_newsCacheKey, jsonEncode(cacheData));
      debugPrint('✅ ${news.length} noticias guardadas en caché');

      // Agregar las primeras 5 noticias al LRU
      for (final newsItem in news.take(5)) {
        _lruCache.put(newsItem.id, newsItem);
      }
    } catch (e) {
      debugPrint('❌ Error guardando noticias en caché: $e');
    }
  }

  /// Obtiene noticias desde caché local
  Future<List<NewsModel>?> getCachedNews() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString(_newsCacheKey);

      if (cachedString == null) {
        debugPrint('📭 No hay noticias en caché');
        return null;
      }

      final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;

      // Verificar si el caché ha expirado
      if (cacheAge > _cacheExpiry.inMilliseconds) {
        debugPrint('⏰ Caché de noticias expirado');
        await clearCache();
        return null;
      }

      final newsList = (cacheData['news'] as List)
          .map(
            (newsJson) =>
                NewsModel.fromFirebase('cached_${newsJson['title']}', newsJson),
          )
          .toList();

      debugPrint('📰 ${newsList.length} noticias obtenidas desde caché');
      return newsList;
    } catch (e) {
      debugPrint('❌ Error obteniendo noticias desde caché: $e');
      return null;
    }
  }

  /// Obtiene noticias más usadas según LRU cuando no hay conexión
  Future<List<NewsModel>> getMostUsedNews() async {
    try {
      // Obtener noticias del LRU Cache (máximo 5)
      final lruNews = _lruCache.getMostUsedNews();

      if (lruNews.isNotEmpty) {
        debugPrint('📊 ${lruNews.length} noticias más usadas desde LRU');
        return lruNews;
      }

      // Si no hay noticias en LRU, intentar desde caché general
      final allCachedNews = await getCachedNews();
      if (allCachedNews != null && allCachedNews.isNotEmpty) {
        // Tomar las primeras 5 y agregarlas al LRU
        final firstFive = allCachedNews.take(5).toList();
        for (final news in firstFive) {
          _lruCache.put(news.id, news);
        }
        return firstFive;
      }

      return [];
    } catch (e) {
      debugPrint('❌ Error obteniendo noticias más usadas: $e');
      return [];
    }
  }

  /// Registra el uso de una noticia (para LRU)
  Future<void> recordNewsUsage(String newsId, NewsModel news) async {
    try {
      // Usar el LRU Cache para registrar el uso
      _lruCache.put(newsId, news);
      debugPrint('📈 Uso registrado en LRU para: ${news.title}');
    } catch (e) {
      debugPrint('❌ Error registrando uso de noticia: $e');
    }
  }

  /// Verifica si hay conexión a internet
  Future<bool> hasInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasConnection =
          connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi);

      debugPrint(
        '🌐 Conexión a internet: ${hasConnection ? "Disponible" : "No disponible"}',
      );
      return hasConnection;
    } catch (e) {
      debugPrint('❌ Error verificando conexión: $e');
      return false;
    }
  }

  /// Limpia toda la caché de noticias
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_newsCacheKey);
      _lruCache.clear();
      debugPrint('🗑️ Caché de noticias limpiada');
    } catch (e) {
      debugPrint('❌ Error limpiando caché: $e');
    }
  }

  /// Obtiene estadísticas del caché
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString(_newsCacheKey);

      if (cachedString == null) {
        return {
          'cached_count': 0,
          'cache_age_hours': 0,
          'cache_size_mb': 0.0,
          'has_internet': await hasInternetConnection(),
          'lru_stats': _lruCache.getStats(),
        };
      }

      final cacheData = jsonDecode(cachedString) as Map<String, dynamic>;
      final timestamp = cacheData['timestamp'] as int;
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      final cacheSizeMB = cachedString.length / (1024 * 1024);

      return {
        'cached_count': cacheData['count'] ?? 0,
        'cache_age_hours': (cacheAge / (1000 * 60 * 60)).round(),
        'cache_size_mb': double.parse(cacheSizeMB.toStringAsFixed(2)),
        'has_internet': await hasInternetConnection(),
        'lru_stats': _lruCache.getStats(),
      };
    } catch (e) {
      debugPrint('❌ Error obteniendo estadísticas de caché: $e');
      return {
        'cached_count': 0,
        'cache_age_hours': 0,
        'cache_size_mb': 0.0,
        'has_internet': false,
        'lru_stats': {},
      };
    }
  }

  /// Cache para imágenes de noticias
  Future<void> cacheNewsImage(String imageUrl) async {
    try {
      await _cacheManager.getSingleFile(imageUrl);
      debugPrint('🖼️ Imagen cacheada: $imageUrl');
    } catch (e) {
      debugPrint('❌ Error cacheando imagen: $e');
    }
  }

  /// Obtiene imagen desde caché
  Future<String?> getCachedImagePath(String imageUrl) async {
    try {
      final fileInfo = await _cacheManager.getFileFromCache(imageUrl);
      return fileInfo?.file.path;
    } catch (e) {
      debugPrint('❌ Error obteniendo imagen desde caché: $e');
      return null;
    }
  }

  /// Obtiene estadísticas del caché LRU
  Map<String, dynamic> getLRUStats() {
    return _lruCache.getStats();
  }

  /// Limpia el caché LRU
  void clearLRU() {
    _lruCache.clear();
  }
}

/// Extensión para facilitar el uso del cache manager
extension NewsCacheExtension on NewsModel {
  /// Registra que esta noticia fue usada
  Future<void> recordUsage() async {
    await NewsCacheManager.instance.recordNewsUsage(id, this);
  }

  /// Cachea la imagen de esta noticia
  Future<void> cacheImage() async {
    if (imageUrl.isNotEmpty) {
      await NewsCacheManager.instance.cacheNewsImage(imageUrl);
    }
  }
}
