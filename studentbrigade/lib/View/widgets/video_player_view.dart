import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../Models/videoMod.dart';
import '../../Caches/video_cache_manager.dart';
import '../../Services/connectivity_service.dart';
import 'dart:io';

class VideoPlayerView extends StatefulWidget {
  final VideoMod video;
  const VideoPlayerView({super.key, required this.video});

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  late VideoPlayerController _c;
  late Future<void> _init;
  final VideoCacheManager _cacheManager = VideoCacheManager();
  final ConnectivityService _connectivity = ConnectivityService();
  bool _hasError = false;
  String _errorMessage = '';
  bool _isOfflineAndNotCached = false;

  bool get _isMuted => _c.value.volume == 0.0;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // Verificar si hay internet
      await _connectivity.initialize();
      final hasInternet = _connectivity.hasInternet;

      if (hasInternet) {
        // Con internet: usar URL normal y cachear en background
        print('🌐 Reproduciendo video online: ${widget.video.url}');
        _c = VideoPlayerController.networkUrl(Uri.parse(widget.video.url));

        // Cachear video en background para uso futuro
        _cacheManager.cacheVideo(widget.video.url);
      } else {
        // Sin internet: intentar usar video cacheado
        print('📱 Sin internet, buscando video en cache...');
        final cachedFile = await _cacheManager.getCachedVideo(widget.video.url);

        if (cachedFile != null && cachedFile.existsSync()) {
          print('✅ Video encontrado en cache: ${cachedFile.path}');
          _c = VideoPlayerController.file(cachedFile);
        } else {
          // Verificar si este video está en los cacheados
          final cachedVideos = await _cacheManager.getCachedVideosOnly();
          final isOfflineVideo = cachedVideos.any(
            (v) => v.url == widget.video.url,
          );

          if (isOfflineVideo) {
            print('⏳ Video debería estar en cache pero aún no está listo...');
            // Esperar un poco más y reintentar
            await Future.delayed(Duration(seconds: 1));
            final retryFile = await _cacheManager.getCachedVideo(
              widget.video.url,
            );

            if (retryFile != null && retryFile.existsSync()) {
              print('✅ Video encontrado en reintento: ${retryFile.path}');
              _c = VideoPlayerController.file(retryFile);
            } else {
              print('❌ Video offline no disponible aún');
              _isOfflineAndNotCached = true;
              _hasError = true;
              _errorMessage =
                  'Video cargando...\nIntenta de nuevo en unos segundos.';

              _c = VideoPlayerController.networkUrl(Uri.parse(''));
              _init = Future.value();
              if (mounted) setState(() {});
              return;
            }
          } else {
            print('❌ Video no está en cache y no hay internet');
            _isOfflineAndNotCached = true;
            _hasError = true;
            _errorMessage =
                'Este video no está disponible sin conexión.\nConéctate a internet para verlo.';

            _c = VideoPlayerController.networkUrl(Uri.parse(''));
            _init = Future.value();
            if (mounted) setState(() {});
            return;
          }
        }
      }

      _init = _c
          .initialize()
          .then((_) async {
            // 🔇 Para Web: inicia en mute para no bloquear el autoplay
            // 🔊 Para móviles/escritorio: arranca con volumen normal
            await _c.setVolume(kIsWeb ? 0.0 : 1.0);
            _hasError = false;
            _errorMessage = '';
            if (mounted) setState(() {});
          })
          .catchError((error) {
            print('❌ Error inicializando video player: $error');
            _hasError = true;
            _errorMessage =
                'Error cargando el video.\nVerifica tu conexión a internet.';
            if (mounted) setState(() {});
          });
    } catch (e) {
      print('❌ Error en _initializePlayer: $e');
      _hasError = true;
      _errorMessage = 'Error inesperado.\nIntenta de nuevo.';

      // Crear controller dummy
      _c = VideoPlayerController.networkUrl(Uri.parse(''));
      _init = Future.value();
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    // Si está muteado en Web, al presionar Play lo subimos: gesto del usuario ✔️
    if (kIsWeb && _isMuted) {
      await _c.setVolume(1.0);
    }
    if (_c.value.isPlaying) {
      await _c.pause();
    } else {
      await _c.play();
    }
    setState(() {});
  }

  Future<void> _toggleMute() async {
    await _c.setVolume(_isMuted ? 1.0 : 0.0);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _init,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (_hasError || _c.value.hasError) {
          return SizedBox(
            height: 220,
            child: Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isOfflineAndNotCached
                          ? Icons.wifi_off
                          : Icons.error_outline,
                      color: Colors.white70,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _errorMessage.isNotEmpty
                          ? _errorMessage
                          : (_c.value.errorDescription ??
                                'Error loading video'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Stack(
          children: [
            AspectRatio(
              aspectRatio: (_c.value.aspectRatio == 0)
                  ? 16 / 9
                  : _c.value.aspectRatio,
              child: VideoPlayer(_c),
            ),
            // 🔊 Botón mute/unmute (arriba a la derecha)
            Positioned(
              right: 12,
              top: 12,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Material(
                  color: Colors.black54,
                  child: IconButton(
                    onPressed: _toggleMute,
                    icon: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            // ▶️ / ⏸ FAB (abajo centrado)
            Positioned(
              bottom: 18,
              left: 0,
              right: 0,
              child: Center(
                child: FloatingActionButton(
                  backgroundColor: Colors.redAccent,
                  onPressed: _togglePlay,
                  child: Icon(
                    _c.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 30,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
