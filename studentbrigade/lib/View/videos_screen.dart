import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../Models/videoMod.dart'; // VideoMod, VideosInfo
import '../../VM/VideosVM.dart'; // VideosVM
import 'video_detail_sheet.dart';
import '../VM/Orchestrator.dart'; // tu player

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
    // merge de escuchas: si en el futuro el Orchestrator cambia estado de navegación, etc.
    _listenableMerge = Listenable.merge([_orch, _orch.videoVM]);

    // Cargar datos iniciales del VM (a través del orquestador)
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _orch.videoVM.init();
      setState(() {}); // por si algo inicial depende de contexto
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

  @override
  Widget build(BuildContext context) {
    final vm = _orch.videoVM;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF5EB4B6),
        title: const Text(
          'Training Videos',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
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
                  onSelected: (_) =>
                      vm.setFilter(f), // delega al VM vía orquestador
                  selectedColor: const Color(0xFF5EB4B6),
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
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
                ? const Center(child: Text('No videos found'))
                : ListView.separated(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(16),
                    itemCount: vm.videos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, i) {
                      final v = vm.videos[i];
                      return _VideoCard(
                        video: v,
                        onPlay: () {
                          _orch.openVideoDetails(context, v);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Card estilizada similar a tu mock
class _VideoCard extends StatelessWidget {
  final VideoMod video;
  final VoidCallback onPlay;
  const _VideoCard({required this.video, required this.onPlay});

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
    final nf = NumberFormat.compact();
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPlay,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // thumbnail + duración + play
            Stack(
              children: [
                Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F5F5),
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
                        color: Colors.white.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(12),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 36,
                        color: Color(0xFF5EB4B6),
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
                      color: const Color(0xFF4E2A7F),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _durationText(video.duration),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: -8,
                    children: video.tags
                        .map(
                          (t) => Chip(
                            label: Text(t),
                            backgroundColor: Colors.grey.shade100,
                            labelStyle: const TextStyle(
                              color: Color(0xFF5E5A6B),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${video.author}   •   ${nf.format(video.views)} views   •   ${_timeAgo(video.publishedAt)}',
                    style: TextStyle(color: Colors.grey.shade600),
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
