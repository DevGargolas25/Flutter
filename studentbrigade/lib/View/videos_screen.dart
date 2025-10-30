import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../Models/videoMod.dart'; // VideoMod, VideosInfo
import '../VM/Orchestrator.dart'; // Orchestrator
import 'Auth0/auth_service.dart'; // AuthService
import '../VM/Adapter.dart'; // Adapter

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
    try {
      // Obtener ID del usuario actual desde AuthService
      final userEmail = AuthService.instance.currentUserEmail ?? 'anonymous';
      final userId = userEmail.replaceAll('@', '_').replaceAll('.', '_');

      // Intentar actualizar like solo si no ha dado like antes
      final wasUpdated = await _orch.adapter.updateLikesIfNotLiked(
        userId,
        video.id,
      );

      if (wasUpdated) {
        // Solo actualizar UI si realmente se agregó el like
        final newLikes = video.likes + 1;
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

        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('👍 Like added!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Usuario ya dio like, mostrar mensaje
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You already liked this video!'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Mostrar error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding like: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _handleView(VideoMod video) async {
    try {
      // Obtener ID del usuario actual desde AuthService
      final userEmail = AuthService.instance.currentUserEmail ?? 'anonymous';
      final userId = userEmail.replaceAll('@', '_').replaceAll('.', '_');

      // Intentar actualizar view solo si no ha visto el video antes
      final wasUpdated = await _orch.adapter.updateViewsIfNotViewed(
        userId,
        video.id,
      );

      if (wasUpdated) {
        // Solo actualizar UI si realmente se agregó el view
        final newViews = video.views + 1;
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
      // No mostrar mensaje para views, es más discreto
    } catch (e) {
      print('Error adding view: $e');
      // Views son menos críticos, no mostramos error al usuario
    }
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
class _VideoCard extends StatefulWidget {
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

  @override
  State<_VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<_VideoCard> {
  bool _hasLiked = false;
  bool _isCheckingLike = true;
  final Adapter _adapter = Adapter();

  @override
  void initState() {
    super.initState();
    _checkUserInteractions();
  }

  void _checkUserInteractions() async {
    try {
      final userEmail = AuthService.instance.currentUserEmail ?? 'anonymous';
      final userId = userEmail.replaceAll('@', '_').replaceAll('.', '_');

      final interactions = await _adapter.getUserVideoInteractions(
        userId,
        widget.video.id,
      );

      if (mounted) {
        setState(() {
          _hasLiked = interactions['hasLiked'] ?? false;
          _isCheckingLike = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingLike = false;
        });
      }
    }
  }

  void _handleLike() {
    if (_hasLiked) {
      // Mostrar mensaje de que ya dio like
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You already liked this video!'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Llamar la función original
    widget.onLike();

    // Actualizar estado local
    setState(() {
      _hasLiked = true;
    });
  }

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
          widget.onView(); // Incrementar views al tocar la tarjeta
          widget.onPlay(); // Abrir el video
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
                    image: widget.video.thumbnail.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(widget.video.thumbnail),
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
                      _durationText(widget.video.duration),
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
                    widget.video.title,
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
                    children: widget.video.tags
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
                        '${widget.video.author}   •   ${_timeAgo(widget.video.publishedAt)}',
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
                            '${nf.format(widget.video.views)}',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurface.withOpacity(.7),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Like button (mano)
                          GestureDetector(
                            onTap: _handleLike,
                            child: Row(
                              children: [
                                Icon(
                                  _hasLiked
                                      ? Icons.thumb_up
                                      : Icons.thumb_up_outlined,
                                  size: 16,
                                  color: _hasLiked ? Colors.blue : cs.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.video.likes}',
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
