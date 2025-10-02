import 'package:flutter/material.dart';
import 'widgets/video_player_view.dart';
import '../Models/videoMod.dart';

class VideoDetailsSheet extends StatelessWidget {
  final VideoMod video;
  const VideoDetailsSheet({super.key, required this.video});

  String _timeAgo(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inDays >= 30) return '${(d.inDays / 30).floor()} months ago';
    if (d.inDays >= 7)  return '${(d.inDays / 7).floor()} weeks ago';
    if (d.inDays >= 1)  return '${d.inDays} days ago';
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return DraggableScrollableSheet(
      expand: false,
      maxChildSize: 0.98,
      initialChildSize: 0.92,
      minChildSize: 0.65,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: CustomScrollView(
            controller: scrollCtrl,
            slivers: [
              // Barra superior con colores del tema
              SliverToBoxAdapter(
                child: Container(
                  color: cs.surface,
                  padding: const EdgeInsets.only(top: 12),
                  child: SafeArea(
                    bottom: false,
                    child: SizedBox(
                      height: 48,
                      child: Row(
                        children: [
                          IconButton(
                            color: cs.onSurface,
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          Expanded(
                            child: Text(
                              video.title,
                              style: tt.titleMedium?.copyWith(
                                color: cs.onSurface,
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

              // Área de video (negro, estándar de players)
              const SliverToBoxAdapter(
                child: ColoredBox(
                  color: Colors.black,
                  child: SizedBox.shrink(),
                ),
              ),
              SliverToBoxAdapter(
                child: Container(
                  color: Colors.black,
                  child: VideoPlayerView(video: video),
                ),
              ),

              // Título
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    video.title,
                    style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ),

              // Métricas (views, likes, publicado, duración)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      _Metric(
                        icon: Icons.visibility,
                        text: '${video.views} views',
                      ),
                      _Metric(
                        icon: Icons.thumb_up_alt_outlined,
                        text: '${video.likes}',
                      ),
                      _Metric(
                        icon: Icons.schedule,
                        text: _timeAgo(video.publishedAt),
                      ),
                      _Metric(
                        icon: Icons.timelapse,
                        text: _durationText(video.duration),
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
                  leading: CircleAvatar(
                    backgroundColor: cs.primary,
                    child: Icon(Icons.group, color: cs.onPrimary),
                  ),
                  title: Text(
                    video.author,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  subtitle: Text(
                    'Campus Safety Team',
                    style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(.7)),
                  ),
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
                      Text('Description',
                          style: tt.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          )),
                      const SizedBox(height: 8),
                      Text(
                        (video.description.isEmpty)
                            ? 'No description.'
                            : video.description,
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurface.withOpacity(.9),
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

/// Pequeño helper para mostrar un icono + texto usando el tema
class _Metric extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Metric({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: cs.onSurface.withOpacity(.7)),
        const SizedBox(width: 6),
        Text(
          text,
          style: tt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(.7)),
        ),
      ],
    );
  }
}

