import 'package:flutter/material.dart';
import 'package:studentbrigade/Models/videoMod.dart';

class VideosVM extends ChangeNotifier {
  final VideosInfo _repo;
  
  // Estado base
  List<VideoMod> _all = [];
  List<VideoMod> _visible = [];
  String _query = '';
  String _activeFilter = 'All';
  bool _isLoading = false; // ← Nuevo: para mostrar loading

  // Reproducción
  VideoMod? _currentPlaying;

  VideosVM(this._repo);

  // Getters
  List<VideoMod> get videos => _visible;
  String get query => _query;
  String get activeFilter => _activeFilter;
  VideoMod? get currentPlaying => _currentPlaying;
  bool get isLoading => _isLoading; // ← Nuevo

  final List<String> filters = const [
    'All',
    'Safety',
    'Medical',
    'Training',
    'Emergency',
  ];

  // ← ÚNICO CAMBIO IMPORTANTE: Agregar loading state
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _all = await _repo.fetchAll(); // ← Esto ahora viene de Firebase vía Adapter
      _applyFilters();
    } catch (e) {
      print('❌ Error inicializando videos: $e');
      // Si hay error, _all queda vacío pero la app no se rompe
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ← Método nuevo: Refresh manual
  Future<void> refresh() async {
    await init(); // Reutiliza la lógica de init
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
}