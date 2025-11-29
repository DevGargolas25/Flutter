import 'package:flutter/material.dart';
import 'package:studentbrigade/Models/videoMod.dart';
import 'package:studentbrigade/VM/Adapter.dart';
import '../Caches/video_cache_manager.dart';
import '../Caches/video_lru_cache.dart';
import '../services/connectivity_service.dart';

class VideosVM extends ChangeNotifier {
  final VideosInfo _repo;
  final Adapter adapter;
  final VideoCacheManager _cacheManager = VideoCacheManager();
  final VideoLRUCache _videoLRU = VideoLRUCache.instance;
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
      // MICROOPTIMIZACIÓN: Inicializar cache manager sin esperar
      _cacheManager.initialize();

      // Inicializar conectividad si no está inicializada
      if (_connectivity.status == ConnectivityStatus.unknown) {
        await _connectivity.initialize();
      }

      // OPTIMIZACIÓN: Mostrar videos LRU inmediatamente si están disponibles
      final lruVideos = _videoLRU.getMostUsedVideos();
      if (lruVideos.isNotEmpty) {
        print('⚡ Mostrando ${lruVideos.length} videos LRU inmediatamente');
        _all = lruVideos;
        _applyFilters();
        _isLoading = false;
        notifyListeners(); // UI responsiva inmediata
      }

      if (_connectivity.hasInternet) {
        // MODO ONLINE: Cargar desde Firebase y guardar en caché
        await _loadOnlineVideos();
      } else {
        // MODO OFFLINE: Cargar desde caché local
        await _loadOfflineVideos();
      }
    } catch (e) {
      print('❌ Error inicializando videos: $e');
      // En caso de error, intentar cargar videos LRU como fallback
      final lruVideos = _videoLRU.getMostUsedVideos();
      if (lruVideos.isNotEmpty) {
        _all = lruVideos;
        _applyFilters();
      } else {
        // Último fallback: cargar desde caché
        try {
          await _loadOfflineVideos();
        } catch (fallbackError) {
          print('❌ Error en fallback: $fallbackError');
        }
      }
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

      // Guardar metadata en background
      _cacheManager.saveOfflineVideosMetadata(_all);

      // OPTIMIZACIÓN: Primero verificar si tenemos videos LRU para mostrar inmediatamente
      final lruVideos = _videoLRU.getMostUsedVideos();
      if (lruVideos.isNotEmpty) {
        print('⚡ Usando videos LRU para respuesta inmediata');
        // Temporal: mostrar videos LRU mientras se cargan los nuevos
        final tempVideos = [...lruVideos];
        // Agregar videos nuevos que no estén en LRU
        for (final video in _all.take(5)) {
          if (!lruVideos.any((lru) => lru.id == video.id)) {
            tempVideos.add(video);
          }
        }
        _all = tempVideos;
        _applyFilters();
        notifyListeners(); // Notificar inmediatamente para UI responsiva
      }

      // MICROOPTIMIZACIÓN: Precarga inteligente basada en LRU
      final priorityVideoIds = _videoLRU.getMostUsedVideoIds();
      final priorityVideos = _all
          .where((v) => priorityVideoIds.contains(v.id))
          .toList();

      if (priorityVideos.isNotEmpty) {
        print(
          '🚀 Precargando ${priorityVideos.length} videos prioritarios (LRU)',
        );
        _cacheManager.cachePriorityVideos(
          priorityVideos,
          count: priorityVideos.length,
        );
      }

      // Cachear los primeros 3 videos inmediatamente si no están en LRU
      final newPriorityVideos = _all
          .take(3)
          .where((v) => !priorityVideoIds.contains(v.id))
          .toList();
      if (newPriorityVideos.isNotEmpty) {
        print(
          '📹 Precargando ${newPriorityVideos.length} nuevos videos prioritarios',
        );
        _cacheManager.cachePriorityVideos(
          newPriorityVideos,
          count: newPriorityVideos.length,
        );
      }

      // Cachear el resto de videos en background (sin esperar)
      if (_all.length > 6) {
        final remainingVideos = _all.skip(6).toList();
        _cacheManager.cacheMultipleVideos(remainingVideos);
      }

      _applyFilters();
      print(
        '✅ VideosVM: ${_all.length} videos cargados online con optimizaciones LRU',
      );
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

      // OPTIMIZACIÓN: Primero intentar usar videos LRU (más rápido)
      final lruVideos = _videoLRU.getMostUsedVideos();
      if (lruVideos.isNotEmpty) {
        print('⚡ Usando ${lruVideos.length} videos LRU para modo offline');
        _all = lruVideos;
        _applyFilters();
        notifyListeners(); // Respuesta inmediata

        // En background, intentar cargar más videos cacheados
        final cachedVideos = await _cacheManager.getCachedVideosOnly();
        final allVideos = [...lruVideos];

        // Agregar videos cacheados que no estén en LRU
        for (final cachedVideo in cachedVideos) {
          if (!lruVideos.any((lru) => lru.id == cachedVideo.id)) {
            allVideos.add(cachedVideo);
          }
        }

        if (allVideos.length > lruVideos.length) {
          _all = allVideos;
          _applyFilters();
          notifyListeners(); // Segunda actualización con más videos
          print(
            '📱 Agregados ${allVideos.length - lruVideos.length} videos cacheados adicionales',
          );
        }
      } else {
        // Fallback: cargar TODOS los videos que están realmente cacheados
        _all = await _cacheManager.getCachedVideosOnly();
        _applyFilters();
      }

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

    print(
      '📶 VideosVM: Cambio de conectividad - wasOffline: $wasOffline, isNowOnline: $isNowOnline',
    );

    if (wasOffline && isNowOnline) {
      // Cambió de offline a online: cargar todos los videos
      print('🌐 VideosVM: Conexión restaurada, cargando videos completos...');
      _isOfflineMode = false;
      notifyListeners(); // Notificar inmediatamente el cambio de estado
      await _loadOnlineVideos();
    } else if (!wasOffline && !isNowOnline) {
      // Cambió de online a offline: mostrar solo videos LRU/cache
      print('📱 VideosVM: Conexión perdida, mostrando videos offline...');
      _isOfflineMode = true;
      notifyListeners(); // Notificar inmediatamente el cambio de estado
      await _loadOfflineVideos();
    }

    // Notificar cambios finales
    notifyListeners();
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
    _videoLRU.clear();
    print('🗑️ VideosVM: Caché de videos y LRU limpiado');
  }

  /// Obtiene estadísticas del LRU para debugging
  Map<String, dynamic> getLRUStats() {
    return _videoLRU.getStats();
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

    // MICROOPTIMIZACIÓN: Registrar video en LRU para precarga futura
    _videoLRU.put(v.id, v);
    print('📈 Video registrado en LRU: ${v.title}');

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
