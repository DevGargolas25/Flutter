import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../Models/videoMod.dart'; // VideoMod, VideosInfo
import '../../VM/VideosVM.dart'; // VideosVM
import 'video_detail_sheet.dart';
import '../VM/Orchestrator.dart'; // Orchestrator

class VideosPage extends StatefulWidget {
  final Orchestrator orchestrator;
  const VideosPage({super.key, required this.orchestrator});

  @override
  State<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> {
  Orchestrator get _orch => widget.orchestrator;
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  // para redibujar cuando cambie el VM u Orchestrator
  late final Listenable _listenableMerge;

  @override
  void initState() {
    super.initState();

    _listenableMerge = Listenable.merge([_orch, _orch.videoVM]);

    // Cargar datos iniciales del VM (a través del orquestador)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _orch.videoVM.init();
      if (mounted) setState(() {});
    });

    // Suscripción para repaint
    _listenableMerge.addListener(_onAnyChange);
  }

  void _onAnyChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _listenableMerge.removeListener(_onAnyChange);
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _handleLike(VideoMod video) async {
    final newLikes = video.likes + 1;
    await _orch.adapter.updateLikes(video.id, newLikes);
    setState(() {
      final updatedVideo = VideoMod(
        id: video.id,
        title: video.title,
        author: video.author,
        tags: video.tags,
        url: video.url,
        duration: video.duration,
        views: video.views,
        publishedAt: video.publishedAt,
        thumbnail: video.thumbnail,
        description: video.description,
        likes: newLikes,
      );
      _orch.videoVM.updateVideo(updatedVideo);
    });
  }

  void _handleView(VideoMod video) async {
    final newViews = video.views + 1;
    await _orch.adapter.updateViews(video.id, newViews);
    setState(() {
      final updatedVideo = VideoMod(
        id: video.id,
        title: video.title,
        author: video.author,
        tags: video.tags,
        url: video.url,
        duration: video.duration,
        views: newViews,
        publishedAt: video.publishedAt,
        thumbnail: video.thumbnail,
        description: video.description,
        likes: video.likes,
      );
      _orch.videoVM.updateVideo(updatedVideo);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = _orch.videoVM;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.primary,
        title: Text(
          'Training Videos',
          style: tt.titleLarge?.copyWith(color: cs.onPrimary),
        ),
        iconTheme: IconThemeData(color: cs.onPrimary),
      ),
      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: vm.search, // a través del orquestador.videoVM
              decoration: InputDecoration(
                hintText: 'Search videos...',
                prefixIcon: Icon(Icons.search, color: cs.primary),
                filled: true,
                fillColor:
                    theme.inputDecorationTheme.fillColor ?? cs.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                hintStyle: tt.bodyMedium?.copyWith(
                  color: cs.onSurface.withOpacity(.6),
                ),
              ),
              style: tt.bodyMedium?.copyWith(color: cs.onSurface),
            ),
          ),

          // Filtros (chips)
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: vm.filters.length,
              itemBuilder: (_, i) {
                final f = vm.filters[i];
                final selected = vm.activeFilter == f;
                return ChoiceChip(
                  label: Text(f),
                  selected: selected,
                  onSelected: (_) => vm.setFilter(f),
                  selectedColor: cs.primary,
                  backgroundColor: cs.surface,
                  side: BorderSide(color: cs.outlineVariant),
                  labelStyle: TextStyle(
                    color: selected ? cs.onPrimary : cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
            ),
          ),

          const SizedBox(height: 8),

          // Lista de videos
          Expanded(
            child: vm.videos.isEmpty
                ? Center(
                    child: Text(
                      'No videos found',
                      style: tt.bodyLarge?.copyWith(color: cs.onSurface),
                    ),
                  )
                : ListView.separated(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: vm.videos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, i) {
                      final v = vm.videos[i];
                      return _VideoCard(
                        video: v,
                        onPlay: () => _orch.openVideoDetails(context, v),
                        onLike: () => _handleLike(v),
                        onView: () => _handleView(v),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Card estilizada, sin colores fijos: usa el tema
class _VideoCard extends StatelessWidget {
  final VideoMod video;
  final VoidCallback onPlay;
  final VoidCallback onLike;
  final VoidCallback onView;

  const _VideoCard({
    required this.video,
    required this.onPlay,
    required this.onLike,
    required this.onView,
  });

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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final nf = NumberFormat.compact();

    return Card(
      color: theme.cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          onView(); // Incrementar views al tocar la tarjeta
          onPlay(); // Abrir el video
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // thumbnail + duración + play
            Stack(
              children: [
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: cs.surfaceVariant,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    image: video.thumbnail.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(video.thumbnail),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surface.withOpacity(.7),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        size: 36,
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _durationText(video.duration),
                      style: tt.labelLarge?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // info
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tags/chips
                  Wrap(
                    spacing: 8,
                    runSpacing: -8,
                    children: video.tags
                        .map(
                          (t) => Chip(
                            label: Text(t),
                            backgroundColor: cs.surfaceVariant,
                            labelStyle: tt.labelMedium?.copyWith(
                              color: cs.onSurface,
                            ),
                            padding: EdgeInsets.zero,
                            side: BorderSide(color: cs.outlineVariant),
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${video.author}   •   ${_timeAgo(video.publishedAt)}',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurface.withOpacity(.7),
                        ),
                      ),
                      Row(
                        children: [
                          // Views (ojo)
                          Icon(
                            Icons.remove_red_eye,
                            size: 16,
                            color: cs.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${nf.format(video.views)}',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(.7),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Like button (mano)
                          GestureDetector(
                            onTap: onLike,
                            child: Row(
                              children: [
                                Icon(
                                  Icons.thumb_up,
                                  size: 16,
                                  color: cs.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${video.likes}',
                                  style: tt.bodySmall?.copyWith(
                                    color: cs.onSurface.withOpacity(.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
