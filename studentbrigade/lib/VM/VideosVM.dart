import 'package:flutter/material.dart';
import 'package:studentbrigade/Models/videoMod.dart';

class VideosVM extends ChangeNotifier {
  final VideosInfo _repo;
  // Estado base
  List<VideoMod> _all = [];
  List<VideoMod> _visible = [];
  String _query = '';
  String _activeFilter = 'All';

  // Reproducción
  VideoMod? _currentPlaying;

  VideosVM(this._repo);

  List<VideoMod> get videos => _visible;
  String get query => _query;
  String get activeFilter => _activeFilter;
  VideoMod? get currentPlaying => _currentPlaying;

  final List<String> filters = const [
    'All',
    'Safety',
    'Medical',
    'Training',
    'Emergency',
  ];

  Future<void> init() async {
    _all = await _repo.fetchAll();
    _applyFilters();
  }

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
