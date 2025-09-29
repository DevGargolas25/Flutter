import 'package:flutter/material.dart';
import 'video.dart';
import 'widgets/video_card.dart';

class VideosScreen extends StatefulWidget {
  const VideosScreen({super.key});
  static const routeName = '/videos';

  @override
  State<VideosScreen> createState() => _VideosScreenState();
}

class _VideosScreenState extends State<VideosScreen> {
  final headerColor = const Color(0xFF62B6B7);
  final _searchCtrl = TextEditingController();

  // Filtros disponibles
  final List<String> _filters = const [
    'All',
    'Safety',
    'Medical',
    'Training',
    'Emergency',
  ];
  String _activeFilter = 'All';

  // Datos mock
  final List<VideoItem> _allVideos = const [
    VideoItem(
      id: 'v1',
      title: 'Campus Emergency Procedures',
      tags: ['Emergency', 'Safety'],
      channel: 'Student Brigade',
      views: '2.3k views',
      timeAgo: '2 weeks ago',
      duration: '5:24',
    ),
    VideoItem(
      id: 'v2',
      title: 'First Aid: CPR Basics',
      tags: ['Medical', 'Training'],
      channel: 'Student Brigade',
      views: '1.1k views',
      timeAgo: '1 week ago',
      duration: '8:15',
    ),
    VideoItem(
      id: 'v3',
      title: 'Fire Drill Walkthrough',
      tags: ['Safety', 'Training'],
      channel: 'Student Brigade',
      views: '3.9k views',
      timeAgo: '3 days ago',
      duration: '6:40',
    ),
    VideoItem(
      id: 'v4',
      title: 'How to Use an AED',
      tags: ['Medical', 'Emergency'],
      channel: 'Student Brigade',
      views: '7.2k views',
      timeAgo: '4 weeks ago',
      duration: '9:03',
    ),
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<VideoItem> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    return _allVideos.where((v) {
      final byFilter = _activeFilter == 'All' || v.tags.contains(_activeFilter);
      final byQuery =
          q.isEmpty ||
          v.title.toLowerCase().contains(q) ||
          v.tags.any((t) => t.toLowerCase().contains(q)) ||
          v.channel.toLowerCase().contains(q);
      return byFilter && byQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ---------- Header + buscador ----------
            Container(
              width: double.infinity,
              color: headerColor,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Training Videos',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.black54),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Search videos...',
                              hintStyle: TextStyle(color: Colors.black45),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        if (_searchCtrl.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.black45,
                            ),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() {});
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ---------- Chips de filtro + “scroll bar” decorativa ----------
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Column(
                children: [
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemBuilder: (_, i) {
                        final label = _filters[i];
                        final selected = _activeFilter == label;
                        return ChoiceChip(
                          label: Text(label),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _activeFilter = label),
                          selectedColor: const Color(0xFFAED9DA),
                          labelStyle: TextStyle(
                            color: selected
                                ? const Color(0xFF1C6E70)
                                : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                          backgroundColor: const Color(0xFFF3F6F7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemCount: _filters.length,
                    ),
                  ),
                  // barrita decorativa entre flechas (estática)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 6, 6, 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.black54,
                          size: 22,
                        ),
                        Expanded(
                          child: Container(
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFBFCBCD),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FractionallySizedBox(
                                widthFactor: 0.45, // simulación del “scroll”
                                child: Container(
                                  color: const Color(0xFF5F6D70),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.black54,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ---------- Lista de videos ----------
            Expanded(
              child: ListView.builder(
                itemCount: _filtered.length,
                itemBuilder: (_, i) => VideoCard(
                  video: _filtered[i],
                  onTap: () {
                    // Solo front: puedes mostrar un snackbar o navegar a un detalle mock
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Open: ${_filtered[i].title}')),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
