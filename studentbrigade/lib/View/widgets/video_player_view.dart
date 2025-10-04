import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../Models/videoMod.dart';

class VideoPlayerView extends StatefulWidget {
  final VideoMod video;
  const VideoPlayerView({super.key, required this.video});

  @override
  State<VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<VideoPlayerView> {
  late VideoPlayerController _c;
  late Future<void> _init;

  bool get _isMuted => _c.value.volume == 0.0;

  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.networkUrl(Uri.parse(widget.video.url));
    _init = _c.initialize().then((_) async {
      // 🔇 Para Web: inicia en mute para no bloquear el autoplay
      // 🔊 Para móviles/escritorio: arranca con volumen normal
      await _c.setVolume(kIsWeb ? 0.0 : 1.0);
      setState(() {});
    });
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
        if (_c.value.hasError) {
          return SizedBox(
            height: 220,
            child: Center(
              child: Text(
                _c.value.errorDescription ?? 'Error loading video',
                style: const TextStyle(color: Colors.white),
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
