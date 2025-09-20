import 'dart:async';
import 'package:flutter/material.dart';
import './widgets/rotating_image_box.dart'; // o reemplaza por Image.asset('assets/medical.png', fit: BoxFit.cover)

typedef VideoSelect = void Function(int videoId);

class HomePage extends StatefulWidget {
  final String userName;
  final VoidCallback? onNavigateToVideos;
  final VoidCallback? onOpenProfile;
  final VideoSelect? onVideoSelect;

  const HomePage({
    super.key,
    this.userName = 'John',
    this.onNavigateToVideos,
    this.onOpenProfile,
    this.onVideoSelect,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // ===== Notificaciones (rotan cada 10s) =====
  final List<String> notifications = const [
    'Campus safety drill scheduled for tomorrow at 2 PM',
    'New emergency exits have been installed in the library',
    'Weather alert: Strong winds expected this afternoon',
    'Student Brigade meeting tonight at 7 PM in room 203',
    'Emergency contact information has been updated',
    'Fire safety equipment inspection completed successfully',
    'Campus security patrol has been increased during evening hours',
  ];
  int currentNotificationIndex = 0;

  // ===== Videos (mock) =====
  final List<_Video> videos = const [
    _Video(
      id: 1,
      title: 'Campus Emergency Procedures',
      category: 'Emergency',
      duration: '5:24',
      views: '2.3k',
      likes: '318',
      uploadDate: '2 days ago',
      description:
      'Learn the key steps to follow during campus emergencies, including evacuation routes, assembly points, and communication protocols.',
    ),
    _Video(
      id: 2,
      title: 'First Aid Basics',
      category: 'Medical',
      duration: '8:15',
      views: '1.8k',
      likes: '245',
      uploadDate: '1 week ago',
      description:
      'A practical overview of first aid essentials: CPR basics, bleeding control, and stabilizing injuries until help arrives.',
    ),
    _Video(
      id: 3,
      title: 'Evacuation & Fire Drills',
      category: 'Safety',
      duration: '6:02',
      views: '1.2k',
      likes: '159',
      uploadDate: '4 days ago',
      description:
      'Understand alarm types, safe exit strategies, and how to assist others during building evacuations and fire drills.',
    ),
    _Video(
      id: 4,
      title: 'Responding to Earthquakes on Campus',
      category: 'Emergency',
      duration: '7:41',
      views: '980',
      likes: '121',
      uploadDate: '3 weeks ago',
      description:
      'Best practices before, during, and after an earthquake, with on-campus examples and safety recommendations.',
    ),
    _Video(
      id: 5,
      title: 'Personal Safety: Tips for Evening Hours',
      category: 'Safety',
      duration: '4:58',
      views: '1.1k',
      likes: '204',
      uploadDate: '5 days ago',
      description:
      'Simple routines and tools to increase your personal safety when moving around campus at night.',
    ),
  ];

  int get currentHourVideoIndex => DateTime.now().hour % videos.length;
  late int featuredIndex;

  Timer? _notifTimer;
  Timer? _hourTimer;

  @override
  void initState() {
    super.initState();
    featuredIndex = currentHourVideoIndex;

    _notifTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      setState(() {
        currentNotificationIndex =
            (currentNotificationIndex + 1) % notifications.length;
      });
    });

    _hourTimer = Timer.periodic(const Duration(hours: 1), (_) {
      if (!mounted) return;
      setState(() => featuredIndex = currentHourVideoIndex);
    });
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    _hourTimer?.cancel();
    super.dispose();
  }

  void _onVideoTap(_Video v, int index) {
    if (widget.onVideoSelect != null) {
      widget.onVideoSelect!(v.id);
    } else {
      _showVideoModal(v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFC),
      body: SafeArea(
        child: Column(
          children: [
            // ===== Barra superior turquesa =====
            Container(
              color: const Color(0xFF99D2D2),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      notifications[currentNotificationIndex],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF4A2951),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'All notifications',
                    onPressed: () => showAllNotificationsDialog(context, notifications),
                    icon: const Icon(Icons.notifications_none_rounded,
                        size: 20, color: Color(0xFF4A2951)),
                  ),
                  IconButton(
                    tooltip: 'Profile',
                    onPressed: () => showProfileMenuDialog(context, widget.onOpenProfile),
                    icon: const Icon(Icons.account_circle,
                        size: 20, color: Color(0xFF4A2951)),
                  ),
                ],
              ),
            ),

            // ===== Contenido scrollable =====
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                children: [
                  Text('Hi ${widget.userName}!',
                      style: tt.headlineSmall?.copyWith(
                        color: const Color(0xFF4A2951),
                        fontWeight: FontWeight.w700,
                      )),
                  const SizedBox(height: 16),

                  // --- Join the Brigade (SIN altura fija + botón que no desborda) ---
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FBFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF99D2D2).withOpacity(.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        // Ilustración (cuadrada, no empuja el contenido)
                        Expanded(
                          flex: 2,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                            child: AspectRatio(
                              aspectRatio: 1, // 1:1 evita crecimientos raros
                              child: Container(
                                color: Colors.white,
                                child: const RotatingImageBox(), // o Image.asset(...)
                              ),
                            ),
                          ),
                        ),

                        // Contenido
                        Expanded(
                          flex: 3,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Color(0xFF75C1C7),
                                      child: Icon(Icons.group,
                                          color: Colors.white, size: 18),
                                    ),
                                    SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        'Join the Brigade',
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        style: TextStyle(
                                          color: Color(0xFF4A2951),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Become part of the student safety team and help keep our campus secure.',
                                  style: TextStyle(color: Color(0xFF4A2951)),
                                ),
                                const SizedBox(height: 12),

                                // Botón protegido contra overflow
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxWidth: 180),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(0xFF75C1C7),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 18, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        onPressed: widget.onOpenProfile,
                                        child: const Text('Learn More',
                                            overflow: TextOverflow.ellipsis),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --- Learn on Your Own ---
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: const [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(0xFF60B896),
                            child: Icon(Icons.menu_book_rounded,
                                color: Colors.white, size: 18),
                          ),
                          SizedBox(width: 10),
                          Text('Learn on Your Own',
                              style: TextStyle(
                                  color: Color(0xFF4A2951),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600)),
                        ]),
                        const SizedBox(height: 6),
                        const Text(
                          'Watch training videos and safety guides at your own pace.',
                          style: TextStyle(color: Color(0xFF4A2951), fontSize: 13),
                        ),
                        const SizedBox(height: 12),

                        // Carrusel: altura suficiente + tarjeta elástica => sin overflow
                        SizedBox(
                          height: 280, // 270–300 va bien
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            itemCount: videos.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 16),
                            itemBuilder: (context, i) {
                              final v = videos[i];
                              final isFeatured = i == featuredIndex;
                              return _VideoCard(
                                video: v,
                                isFeatured: isFeatured,
                                onTap: () => _onVideoTap(v, i),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: widget.onNavigateToVideos,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF75C1C7),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('View All Videos'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =================== Modal de Video (fallback) ===================
  void _showVideoModal(_Video v) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(ctx).size.height,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                color: const Color(0xFF111111),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    Expanded(
                      child: Text(
                        v.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              // Player placeholder
              Expanded(
                child: Container(
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_circle_fill,
                          size: 64, color: Colors.white70),
                      const SizedBox(height: 8),
                      const Text('Video Player',
                          style: TextStyle(color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('Duration: ${v.duration}',
                          style: const TextStyle(color: Colors.white60)),
                    ],
                  ),
                ),
              ),
              // Info
              Container(
                color: Colors.white,
                constraints:
                BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .4),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _stat(Icons.visibility_outlined, '${v.views} views'),
                          const SizedBox(width: 16),
                          _stat(Icons.thumb_up_alt_outlined, v.likes),
                          const SizedBox(width: 16),
                          Text(v.uploadDate,
                              style: const TextStyle(color: Colors.black54)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE3F2FD),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.groups_2,
                                color: Color(0xFF1E88E5)),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Student Brigade',
                                  style:
                                  TextStyle(fontWeight: FontWeight.w600)),
                              Text('Campus Safety Team',
                                  style: TextStyle(color: Colors.black54)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Description',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(v.description, style: const TextStyle(height: 1.4)),
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

  Widget _stat(IconData icon, String text) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 18, color: Colors.black54),
      const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: Colors.black54)),
    ],
  );
}

/* =================== Video Card ELÁSTICA (sin overflow) =================== */
class _VideoCard extends StatelessWidget {
  final _Video video;
  final bool isFeatured;
  final VoidCallback onTap;

  const _VideoCard({
    required this.video,
    required this.isFeatured,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 288, // ~ w-72
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isFeatured
                ? const Color(0xFF75C1C7)
                : const Color(0xFF99D2D2).withOpacity(.3),
            width: isFeatured ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isFeatured ? .08 : .04),
              blurRadius: isFeatured ? 12 : 8,
              offset: const Offset(0, 6),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail elástico
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF75C1C7).withOpacity(.9),
                      const Color(0xFF60B896).withOpacity(.9),
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.play_arrow_rounded,
                      size: 36, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Tag
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF75C1C7),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                video.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),

            // Texto + métricas (elástico)
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF4A2951),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      // pill de duración
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7FBFC),
                            border: Border.all(
                                color: const Color(0xFF99D2D2).withOpacity(.3)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule,
                                  size: 16, color: Colors.black54),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  video.duration,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${video.views} views',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (isFeatured) ...[
              const SizedBox(height: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF75C1C7).withOpacity(.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text('✨ Now Featured',
                    style: TextStyle(
                        color: Color(0xFF75C1C7), fontWeight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/* =================== Modelo de datos =================== */
class _Video {
  final int id;
  final String title;
  final String category;
  final String duration;
  final String views;
  final String likes;
  final String uploadDate;
  final String description;

  const _Video({
    required this.id,
    required this.title,
    required this.category,
    required this.duration,
    required this.views,
    required this.likes,
    required this.uploadDate,
    required this.description,
  });
}

/* =================== Modales reutilizables =================== */
Future<void> showProfileMenuDialog(BuildContext context, VoidCallback? onOpenProfile) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(.6),
    builder: (ctx) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header turquesa
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              decoration: const BoxDecoration(
                color: Color(0xFF75C1C7),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: const [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white24,
                    child: Icon(Icons.person, color: Colors.white, size: 28),
                  ),
                  SizedBox(height: 8),
                  Text('Profile & Settings',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('Manage your account and preferences',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: InkWell(
                onTap: () {
                  Navigator.pop(ctx);
                  onOpenProfile?.call();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FBFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF99D2D2).withOpacity(.3)),
                  ),
                  child: Row(
                    children: const [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFF99D2D2),
                        child:
                        Icon(Icons.person_outline, color: Colors.white),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('Profile Settings',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

Future<void> showAllNotificationsDialog(
    BuildContext context, List<String> notifications) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withOpacity(.3),
    builder: (ctx) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                        color: const Color(0xFF99D2D2).withOpacity(.2)),
                  ),
                ),
                child: Row(
                  children: const [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFF75C1C7),
                      child: Icon(Icons.notifications_none_rounded,
                          color: Colors.white, size: 18),
                    ),
                    SizedBox(width: 10),
                    Text('All Notifications',
                        style: TextStyle(
                            color: Color(0xFF4A2951),
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: notifications
                        .map((n) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF99D2D2)
                                .withOpacity(.25)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(.03),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            radius: 14,
                            backgroundColor: Color(0xFF75C1C7),
                            child: Icon(Icons.notifications,
                                size: 14, color: Colors.white),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              n,
                              style: const TextStyle(
                                  color: Color(0xFF4A2951)),
                            ),
                          ),
                        ],
                      ),
                    ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF75C1C7),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

