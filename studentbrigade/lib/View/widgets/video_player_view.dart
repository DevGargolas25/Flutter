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

  @override
  void initState() {
    super.initState();
    _c = VideoPlayerController.networkUrl(Uri.parse(widget.video.url));
    _init = _c.initialize().then((_) async {
      if (kIsWeb) await _c.setVolume(0);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
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
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: (_c.value.aspectRatio == 0)
                  ? 16 / 9
                  : _c.value.aspectRatio,
              child: VideoPlayer(_c),
            ),
            Positioned(
              bottom: 18,
              child: FloatingActionButton(
                backgroundColor: Colors.redAccent,
                onPressed: () async {
                  if (_c.value.isPlaying) {
                    await _c.pause();
                  } else {
                    await _c.play();
                  }
                  setState(() {});
                },
                child: Icon(
                  _c.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  size: 30,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
