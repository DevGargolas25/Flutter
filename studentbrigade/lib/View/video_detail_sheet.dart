import 'package:flutter/material.dart';
import 'widgets/video_player_view.dart';
import '../Models/videoMod.dart';

class VideoDetailsSheet extends StatelessWidget {
  final VideoMod video;
  const VideoDetailsSheet({super.key, required this.video});

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inDays >= 30) return '${(d.inDays / 30).floor()} months ago';
    if (d.inDays >= 7) return '${(d.inDays / 7).floor()} weeks ago';
    if (d.inDays >= 1) return '${d.inDays} days ago';
    if (d.inHours >= 1) return '${d.inHours} hours ago';
    return 'just now';
  }

  String _durationText(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      maxChildSize: 0.98,
      initialChildSize: 0.92,
      minChildSize: 0.65,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: CustomScrollView(
            controller: scrollCtrl,
            slivers: [
              // Barra superior oscura con título y back
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.black87,
                  padding: const EdgeInsets.only(top: 12),
                  child: SafeArea(
                    bottom: false,
                    child: SizedBox(
                      height: 48,
                      child: Row(
                        children: [
                          IconButton(
                            color: Colors.white,
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Text(
                              video.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Área de video (fondo negro)
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.black,
                  child: VideoPlayerView(video: video),
                ),
              ),

              // Título / métricas
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    video.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.visibility,
                        size: 18,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${video.views} views',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.thumb_up_alt_outlined,
                        size: 18,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${video.likes}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.schedule,
                        size: 18,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _timeAgo(video.publishedAt),
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.timelapse,
                        size: 18,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _durationText(video.duration),
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),
              const SliverToBoxAdapter(child: Divider(height: 1)),

              // Autor / canal
              SliverToBoxAdapter(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  leading: const CircleAvatar(child: Icon(Icons.group)),
                  title: Text(
                    video.author,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text('Campus Safety Team'),
                  trailing: FilledButton(
                    onPressed: () {},
                    child: const Text('Subscribe'),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: Divider(height: 1)),

              // Descripción
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        (video.description.isEmpty)
                            ? 'No description.'
                            : video.description,
                        style: TextStyle(
                          color: Colors.grey.shade800,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
