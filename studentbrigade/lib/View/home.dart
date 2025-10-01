import 'dart:async';
import 'package:flutter/material.dart';
import 'package:studentbrigade/VM/Orchestrator.dart';
import 'profile_page.dart';
import 'widgets/video_card.dart';
import 'widgets/rotating_image_box.dart'; // o reemplaza por Image.asset('assets/medical.png', fit: BoxFit.cover)
import 'widgets/rotating_image_box.dart';
import 'analytics.dart';
import 'Auth0/auth_service.dart';
import 'Auth0/auth_gate.dart';
import 'nav_shell.dart';
import 'package:url_launcher/url_launcher.dart';


typedef VideoSelect = void Function(int videoId);

class HomePage extends StatefulWidget {
  final Orchestrator orchestrator;
  final String userName;
  final VoidCallback? onNavigateToVideos;
  final VoidCallback? onOpenProfile;
  final VideoSelect? onVideoSelect;

  const HomePage({
    super.key,
    required this.orchestrator,
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

  // Reemplaza el getter:
  int get currentHourVideoIndex {
    final len = widget.orchestrator.videoVM.videos.length;
    if (len == 0) return 0;
    return DateTime.now().hour % len;
  }

  late int featuredIndex;

  Timer? _notifTimer;
  Timer? _hourTimer;

  @override
  void initState() {
    super.initState();

    // timers que ya tenías
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

    // Carga del VM y set del destacado
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = widget.orchestrator.videoVM;
      if (vm.videos.isEmpty) {
        await vm.init();
      }
      if (!mounted) return;
      setState(() {
        featuredIndex = currentHourVideoIndex; // ahora sí con datos reales
      });
    });
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    _hourTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final vm = widget.orchestrator.videoVM;
    final items = vm.videos;
    final creds = AuthService.instance.credentials;
    final roles = creds?.roles ?? [];


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
                    onPressed: () =>
                        showAllNotificationsDialog(context, notifications),
                    icon: const Icon(Icons.notifications_none_rounded,
                        size: 20, color: Color(0xFF4A2951)),
                  ),
                  IconButton(
                    tooltip: 'Profile',
                    onPressed: () =>
                        showProfileMenuDialog(context, widget.onOpenProfile),
                    icon: const Icon(Icons.account_circle,
                        size: 20, color: Color(0xFF4A2951)),
                  ),
                  // 🔹 Nuevo botón de Analytics
                  if (roles.contains('analytics'))
                  IconButton(
                    tooltip: 'Analytics',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AnalyticsPage(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.analytics_outlined,
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
                  Text(
                    'Hi ${widget.userName}!',
                    style: tt.headlineSmall?.copyWith(
                      color: const Color(0xFF4A2951),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // --- Join the Brigade (SIN altura fija + botón que no desborda) ---
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FBFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF99D2D2).withOpacity(.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
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
                                child:
                                    const RotatingImageBox(), // o Image.asset(...)
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
                                      child: Icon(
                                        Icons.group,
                                        color: Colors.white,
                                        size: 18,
                                      ),
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
                                    constraints: const BoxConstraints(
                                      maxWidth: 180,
                                    ),
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: FilledButton(
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF75C1C7,
                                          ),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 18,
                                            vertical: 12,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        onPressed: () async {
                                          final url = Uri.parse('https://www.instagram.com/beuniandes/');
                                          if (await canLaunchUrl(url)) {
                                            await launchUrl(url, mode: LaunchMode.externalApplication);
                                          } else {
                                            // Fallback si no puede abrir el enlace
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Could not open Instagram link'),
                                                backgroundColor: Colors.red,
                                              ),
                                            );
                                          }
                                        },
                                        child: const Text(
                                          'Learn More',
                                          overflow: TextOverflow.ellipsis,
                                        ),
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
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Color(0xFF60B896),
                              child: Icon(
                                Icons.menu_book_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Learn on Your Own',
                              style: TextStyle(
                                color: Color(0xFF4A2951),
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Watch training videos and safety guides at your own pace.',
                          style: TextStyle(
                            color: Color(0xFF4A2951),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Carrusel: altura suficiente + tarjeta elástica => sin overflow
                        SizedBox(
                          height: 280,
                          child: items.isEmpty
                              ? const Center(child: CircularProgressIndicator())
                              : ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  itemCount: items.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 16),
                                  itemBuilder: (context, i) {
                                    final v =
                                        items[i]; // <-- VideoMod del modelo
                                    final isFeatured =
                                        i == (featuredIndex % vm.videos.length);
                                    return VideoCard(
                                      video: v,
                                      isFeatured: isFeatured,
                                      onTap: () => widget.orchestrator
                                          .openVideoDetails(context, v),
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
 


/* =================== Modales reutilizables =================== */
Future<void> showProfileMenuDialog(
    BuildContext context, VoidCallback? onOpenProfile) {
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

            // Opción: Profile Settings
            Padding(
              padding: const EdgeInsets.all(16),
                child: InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    // Navegar a ProfilePage mediante callback
                    onOpenProfile?.call();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7FBFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF99D2D2).withOpacity(.3),
                      ),
                    ),
                    child: Row(
                      children: const [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFF99D2D2),
                          child: Icon(
                            Icons.person_outline,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Profile Settings',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),

            // 🔹 Nuevo botón: Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  await AuthService.instance.logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const AuthGate(childWhenAuthed: NavShell())),
                        (_) => false,
                  );
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
                        child: Icon(Icons.logout, color: Colors.white),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text('Log out',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF4A2951))),
                      ),
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
    BuildContext context,
    List<String> notifications,
  ) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(.3),
      builder: (ctx) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                        color: const Color(0xFF99D2D2).withOpacity(.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: const [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(0xFF75C1C7),
                        child: Icon(
                          Icons.notifications_none_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'All Notifications',
                        style: TextStyle(
                          color: Color(0xFF4A2951),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: notifications
                          .map(
                            (n) => Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(
                                    0xFF99D2D2,
                                  ).withOpacity(.25),
                                ),
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
                                    child: Icon(
                                      Icons.notifications,
                                      size: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      n,
                                      style: const TextStyle(
                                        color: Color(0xFF4A2951),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
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
                        horizontal: 28,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
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
}
