import 'package:flutter/material.dart';
import '../Models/newsModel.dart';
import '../Models/news_cache_manager.dart';

class NewsVM extends ChangeNotifier {
  final NewsService _newsService = NewsService();
  final NewsCacheManager _cacheManager = NewsCacheManager.instance;

  // Exposer para testing
  NewsService get newsService => _newsService;

  // Estado
  List<NewsModel> _news = [];
  List<NewsModel> _filteredNews = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _errorMessage = '';
  String _searchQuery = '';
  NewsModel? _selectedNews;
  bool _isOffline = false;
  bool _isLoadedFromCache = false;

  // Getters
  List<NewsModel> get news => _searchQuery.isEmpty ? _news : _filteredNews;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;
  bool get hasMore => false; // Firebase no necesita paginación para este caso
  NewsModel? get selectedNews => _selectedNews;
  bool get isEmpty => news.isEmpty && !_isLoading;
  String get searchQuery => _searchQuery;
  bool get isOffline => _isOffline;
  bool get isLoadedFromCache => _isLoadedFromCache;

  /// Carga las noticias priorizando caché local
  Future<void> loadNews() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      // 1. Verificar conexión a internet
      final hasConnection = await _cacheManager.hasInternetConnection();
      _isOffline = !hasConnection;

      debugPrint(
        '📰 NewsVM: Iniciando carga de noticias (${hasConnection ? "Online" : "Offline"})',
      );

      if (hasConnection) {
        // 2. Con conexión: intentar cargar desde Firebase primero
        await _loadFromFirebaseWithCache();
      } else {
        // 3. Sin conexión: cargar desde caché usando LRU
        await _loadFromCacheOffline();
      }

      // 4. Si hay una búsqueda activa, filtrar las noticias
      if (_searchQuery.isNotEmpty) {
        _filterNews(_searchQuery);
      }

      debugPrint(
        '✅ NewsVM: ${_news.length} noticias cargadas (caché: $_isLoadedFromCache, offline: $_isOffline)',
      );
    } catch (e) {
      _setError('Error cargando noticias: $e');
      debugPrint('❌ NewsVM: Error cargando noticias: $e');

      // Como último recurso, intentar cargar desde caché
      await _loadFromCacheOffline();
    } finally {
      _setLoading(false);
    }
  }

  /// Carga desde Firebase y actualiza caché
  Future<void> _loadFromFirebaseWithCache() async {
    try {
      // 1. Cargar primero desde caché para respuesta inmediata
      final cachedNews = await _cacheManager.getCachedNews();
      if (cachedNews != null && cachedNews.isNotEmpty) {
        _news = cachedNews;
        _isLoadedFromCache = true;
        notifyListeners(); // Mostrar datos inmediatamente
        debugPrint('⚡ Noticias cargadas desde caché como respuesta rápida');
      }

      // 2. Cargar desde Firebase en background
      final freshNews = await _newsService.fetchNews();

      if (freshNews.isNotEmpty) {
        _news = freshNews;
        _isLoadedFromCache = false;

        // 3. Actualizar caché con datos frescos
        await _cacheManager.cacheNews(freshNews);

        // 4. Pre-cargar imágenes en background
        _precacheImages(freshNews);

        debugPrint(
          '🔄 Caché actualizado con ${freshNews.length} noticias frescas',
        );
      }
    } catch (e) {
      debugPrint('❌ Error cargando desde Firebase: $e');
      // Si falla Firebase, intentar solo desde caché
      await _loadFromCacheOffline();
    }
  }

  /// Carga desde caché cuando no hay conexión (modo offline)
  Future<void> _loadFromCacheOffline() async {
    try {
      final mostUsedNews = await _cacheManager.getMostUsedNews();

      if (mostUsedNews.isNotEmpty) {
        _news = mostUsedNews;
        _isLoadedFromCache = true;
        _isOffline = true;
        debugPrint(
          '📱 Modo offline: ${mostUsedNews.length} noticias más usadas (LRU)',
        );
      } else {
        _setError('No hay noticias disponibles offline');
        debugPrint('📭 Sin noticias en caché para modo offline');
      }
    } catch (e) {
      debugPrint('❌ Error cargando desde caché offline: $e');
      _setError('Error accediendo a noticias offline');
    }
  }

  /// Pre-carga imágenes en background
  void _precacheImages(List<NewsModel> news) {
    for (final newsItem in news.take(10)) {
      // Solo las primeras 10
      if (newsItem.imageUrl.isNotEmpty) {
        newsItem.cacheImage().catchError((e) {
          debugPrint('⚠️ Error pre-cargando imagen: $e');
        });
      }
    }
  }

  /// Busca noticias por término
  Future<void> searchNews(String query) async {
    _searchQuery = query.trim();

    if (_searchQuery.isEmpty) {
      _filteredNews.clear();
      notifyListeners();
      return;
    }

    // Si ya tenemos noticias cargadas, filtrar localmente primero
    if (_news.isNotEmpty) {
      _filterNews(_searchQuery);
    }

    // También buscar en Firebase
    try {
      print('🔍 NewsVM: Buscando noticias con: "$_searchQuery"');
      final searchResults = await _newsService.searchNews(_searchQuery);

      _filteredNews = searchResults;
      print('✅ NewsVM: ${searchResults.length} resultados encontrados');

      notifyListeners();
    } catch (e) {
      print('❌ NewsVM: Error en búsqueda: $e');
      // Si falla la búsqueda remota, usar filtro local
      _filterNews(_searchQuery);
    }
  }

  /// Filtra noticias localmente
  void _filterNews(String query) {
    final lowercaseQuery = query.toLowerCase();

    _filteredNews = _news.where((news) {
      return news.title.toLowerCase().contains(lowercaseQuery) ||
          news.description.toLowerCase().contains(lowercaseQuery) ||
          news.author.toLowerCase().contains(lowercaseQuery) ||
          news.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();

    notifyListeners();
  }

  /// Limpia la búsqueda
  void clearSearch() {
    _searchQuery = '';
    _filteredNews.clear();
    notifyListeners();
  }

  /// Carga más noticias (para scroll infinito) - No necesario para Firebase
  Future<void> loadMoreNews() async {
    // Para Firebase, todas las noticias se cargan de una vez
    print('📰 NewsVM: LoadMore no necesario para Firebase');
  }

  /// Refresca las noticias (pull to refresh)
  Future<void> refreshNews() async {
    await loadNews();
  }

  /// Selecciona una noticia específica y registra su uso
  void selectNews(NewsModel news) {
    _selectedNews = news;
    notifyListeners();

    // Registrar uso para LRU
    news.recordUsage().catchError((e) {
      debugPrint('⚠️ Error registrando uso de noticia: $e');
    });

    debugPrint('📰 NewsVM: Noticia seleccionada: ${news.title}');
  }

  /// Limpia la noticia seleccionada
  void clearSelectedNews() {
    _selectedNews = null;
    notifyListeners();
  }

  /// Busca una noticia por ID y la carga si no está en la lista
  Future<NewsModel?> getNewsById(String id) async {
    try {
      // Primero buscar en la lista actual
      final existingNews = _news.where((news) => news.id == id);
      if (existingNews.isNotEmpty) {
        return existingNews.first;
      }

      // Si no está, intentar cargarla desde el servicio
      final news = await _newsService.getNewsById(id);
      if (news != null) {
        _selectedNews = news;
        notifyListeners();
      }

      return news;
    } catch (e) {
      print('❌ NewsVM: Error obteniendo noticia por ID: $e');
      return null;
    }
  }

  /// Incrementa los likes de una noticia (simulado) - Removido porque no hay likes
  // No se incluye funcionalidad de likes en este modelo

  /// Obtiene noticias por autor
  List<NewsModel> getNewsByAuthor(String author) {
    final sourceList = _searchQuery.isEmpty ? _news : _filteredNews;
    return sourceList.where((news) => news.author == author).toList();
  }

  /// Obtiene estadísticas de noticias
  Map<String, dynamic> getNewsStats() {
    final sourceList = _searchQuery.isEmpty ? _news : _filteredNews;

    if (sourceList.isEmpty) {
      return {
        'total': 0,
        'top_author': 'N/A',
        'latest_date': 'N/A',
        'total_tags': 0,
        'cache_info': 'Sin datos',
        'offline_mode': _isOffline,
      };
    }

    // Encontrar autor con más artículos
    final authorCount = <String, int>{};
    final allTags = <String>{};

    for (final news in sourceList) {
      authorCount[news.author] = (authorCount[news.author] ?? 0) + 1;
      allTags.addAll(news.tags);
    }

    final topAuthor = authorCount.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    // Fecha más reciente
    final latestDate = sourceList
        .map((news) => news.createdAt)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    return {
      'total': sourceList.length,
      'top_author': topAuthor,
      'latest_date': latestDate.toString(),
      'total_tags': allTags.length,
      'cache_info': _isLoadedFromCache ? 'Datos desde caché' : 'Datos frescos',
      'offline_mode': _isOffline,
    };
  }

  /// Obtiene estadísticas del caché
  Future<Map<String, dynamic>> getCacheStats() async {
    return await _cacheManager.getCacheStats();
  }

  /// Limpia toda la caché
  Future<void> clearCache() async {
    await _cacheManager.clearCache();
    debugPrint('🗑️ Caché limpiada por el usuario');
  }

  /// Fuerza la recarga desde Firebase
  Future<void> forceRefresh() async {
    _isLoadedFromCache = false;
    await _loadFromFirebaseWithCache();
    notifyListeners();
  }

  // Métodos privados
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
  }

  @override
  void dispose() {
    super.dispose();
  }
}
