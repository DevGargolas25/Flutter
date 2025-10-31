import 'package:flutter/material.dart';
import 'package:studentbrigade/Models/videoMod.dart';
import 'package:studentbrigade/VM/Adapter.dart';
import '../Caches/video_cache_manager.dart';
import '../Services/connectivity_service.dart';

class VideosVM extends ChangeNotifier {
  final VideosInfo _repo;
  final Adapter adapter;
  final VideoCacheManager _cacheManager = VideoCacheManager();
  final ConnectivityService _connectivity = ConnectivityService();

  // Estado base
  List<VideoMod> _all = [];
  List<VideoMod> _visible = [];
  String _query = '';
  String _activeFilter = 'All';
  bool _isLoading = false;
  bool _isOfflineMode = false;

  // Reproducción
  VideoMod? _currentPlaying;

  VideosVM(this._repo, this.adapter) {
    // Escuchar cambios de conectividad
    _connectivity.addListener(_onConnectivityChanged);
  }

  // Getters
  List<VideoMod> get videos => _visible;
  String get query => _query;
  String get activeFilter => _activeFilter;
  VideoMod? get currentPlaying => _currentPlaying;
  bool get isLoading => _isLoading;
  bool get isOfflineMode => _isOfflineMode;
  bool get hasInternet => _connectivity.hasInternet;

  final List<String> filters = const [
    'All',
    'Safety',
    'Medical',
    'Training',
    'Emergency',
  ];

  // Inicialización con estrategia de conectividad
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Inicializar cache manager
      await _cacheManager.initialize();

      // Inicializar conectividad si no está inicializada
      if (_connectivity.status == ConnectivityStatus.unknown) {
        await _connectivity.initialize();
      }

      if (_connectivity.hasInternet) {
        // MODO ONLINE: Cargar desde Firebase y guardar en caché
        await _loadOnlineVideos();
      } else {
        // MODO OFFLINE: Cargar desde caché local (solo 2 videos)
        await _loadOfflineVideos();
      }
    } catch (e) {
      print('❌ Error inicializando videos: $e');
      // En caso de error, intentar cargar desde caché
      await _loadOfflineVideos();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Carga videos desde Firebase cuando hay internet
  Future<void> _loadOnlineVideos() async {
    try {
      print('🌐 VideosVM: Cargando videos online...');
      _isOfflineMode = false;

      // Cargar desde Firebase
      _all = await _repo.fetchAll();

      // Guardar metadata y cachear videos en background
      await _cacheManager.saveOfflineVideosMetadata(_all);

      // Cachear los primeros 5 videos inmediatamente (prioritario)
      if (_all.isNotEmpty) {
        await _cacheManager.cachePriorityVideos(_all, count: 5);
      }

      // Cachear el resto de videos en background (sin esperar)
      if (_all.length > 5) {
        final remainingVideos = _all.skip(5).toList();
        _cacheManager.cacheMultipleVideos(remainingVideos);
      }

      _applyFilters();
      print('✅ VideosVM: ${_all.length} videos cargados online');
    } catch (e) {
      print('❌ VideosVM: Error cargando videos online: $e');
      rethrow;
    }
  }

  /// Carga TODOS los videos cacheados cuando no hay internet
  Future<void> _loadOfflineVideos() async {
    try {
      print('📱 VideosVM: Cargando videos offline...');
      _isOfflineMode = true;

      // Cargar TODOS los videos que están realmente cacheados
      _all = await _cacheManager.getCachedVideosOnly();

      _applyFilters();
      print('✅ VideosVM: ${_all.length} videos cacheados cargados offline');
    } catch (e) {
      print('❌ VideosVM: Error cargando videos offline: $e');
      _all = [];
      _applyFilters();
    }
  }

  /// Maneja cambios en la conectividad
  void _onConnectivityChanged() async {
    final wasOffline = _isOfflineMode;
    final isNowOnline = _connectivity.hasInternet;

    if (wasOffline && isNowOnline) {
      // Cambió de offline a online: cargar todos los videos
      print('🌐 VideosVM: Conexión restaurada, cargando videos completos...');
      await _loadOnlineVideos();
    } else if (!wasOffline && !isNowOnline) {
      // Cambió de online a offline: mostrar solo 2 videos
      print('📱 VideosVM: Conexión perdida, mostrando videos offline...');
      await _loadOfflineVideos();
    }
  }

  // Refresh manual (fuerza recarga desde Firebase si hay internet)
  Future<void> refresh() async {
    if (_connectivity.hasInternet) {
      await _loadOnlineVideos();
    } else {
      await _loadOfflineVideos();
    }
  }

  /// Verifica conectividad manualmente
  Future<void> checkConnectivity() async {
    await _connectivity.checkConnectivity();
    _onConnectivityChanged();
  }

  /// Limpia el caché de videos
  Future<void> clearCache() async {
    await _cacheManager.clearAllCache();
    print('🗑️ VideosVM: Caché de videos limpiado');
  }

  // ← Todo lo demás queda IGUAL
  void search(String q) {
    _query = q;
    _applyFilters();
  }

  void setFilter(String f) {
    _activeFilter = f;
    _applyFilters();
  }

  void _applyFilters() {
    Iterable<VideoMod> list = _all;

    if (_activeFilter != 'All') {
      list = list.where((v) => v.tags.contains(_activeFilter));
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where(
        (v) =>
            v.title.toLowerCase().contains(q) ||
            v.author.toLowerCase().contains(q) ||
            v.tags.any((t) => t.toLowerCase().contains(q)),
      );
    }

    _visible = list.toList();
    notifyListeners();
  }

  // "Play": solo fija el actual; la vista decide navegar al reproductor
  void play(VideoMod v) {
    _currentPlaying = v;
    notifyListeners();
  }

  void updateVideo(VideoMod updatedVideo) {
    _all = _all.map((v) => v.id == updatedVideo.id ? updatedVideo : v).toList();
    _applyFilters();
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivity.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}
