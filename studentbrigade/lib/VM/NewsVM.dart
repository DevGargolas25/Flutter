import 'package:flutter/material.dart';
import '../Models/newsModel.dart';

class NewsVM extends ChangeNotifier {
  final NewsService _newsService = NewsService();

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

  /// Carga las noticias desde Firebase
  Future<void> loadNews() async {
    if (_isLoading) return;

    _setLoading(true);
    _clearError();

    try {
      print('📰 NewsVM: Cargando noticias desde Firebase...');
      final newsList = await _newsService.fetchNews();

      _news = newsList;

      // Si hay una búsqueda activa, filtrar las noticias
      if (_searchQuery.isNotEmpty) {
        _filterNews(_searchQuery);
      }

      print('✅ NewsVM: ${newsList.length} noticias cargadas desde Firebase');
    } catch (e) {
      _setError('Error cargando noticias: $e');
      print('❌ NewsVM: Error cargando noticias: $e');
    } finally {
      _setLoading(false);
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

  /// Selecciona una noticia específica
  void selectNews(NewsModel news) {
    _selectedNews = news;
    notifyListeners();
    print('📰 NewsVM: Noticia seleccionada: ${news.title}');
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
    };
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
