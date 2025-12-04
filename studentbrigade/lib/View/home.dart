import 'dart:async';
import 'package:flutter/material.dart';
import 'package:studentbrigade/VM/Orchestrator.dart';
import 'widgets/video_card.dart';
import 'widgets/rotating_image_box.dart';
import 'emergency_analytics.dart';
import 'Auth0/auth_service.dart';
import 'Auth0/auth_gate.dart';
import 'nav_shell.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'offline_info_page.dart';
import 'blood_donation_page.dart';
import 'package:http/http.dart' as http;

typedef VideoSelect = void Function(int videoId);

class HomePage extends StatefulWidget {
  final Orchestrator orchestrator;
  final String userName;
  final String? userType;
  final VoidCallback? onNavigateToVideos;
  final VoidCallback? onOpenProfile;
  final VideoSelect? onVideoSelect;

  const HomePage({
    super.key,
    required this.orchestrator,
    this.userName = 'John',
    this.userType,
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

  int get currentHourVideoIndex {
    final len = widget.orchestrator.videoVM.videos.length;
    if (len == 0) return 0;
    return DateTime.now().hour % len;
  }

  late int featuredIndex = 0;

  Timer? _notifTimer;
  Timer? _hourTimer;

  // ===== Unattended para brigadistas =====
  List<Map<String, dynamic>> _unattended = [];
  bool _loadingUnattended = false;
  StreamSubscription<List<Map<String, dynamic>>>? _unattendedSub;
  bool _unattendedIsCached = false;
  DateTime? _unattendedLastUpdated;

  @override
  void initState() {
    super.initState();

    // Notificaciones rotativas
    _notifTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      setState(() {
        currentNotificationIndex =
            (currentNotificationIndex + 1) % notifications.length;
      });
    });

    // Cambio de featured video cada hora
    _hourTimer = Timer.periodic(const Duration(hours: 1), (_) {
      if (!mounted) return;
      setState(() => featuredIndex = currentHourVideoIndex);
    });

    // Inicializar videos una sola vez
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = widget.orchestrator.videoVM;
       await widget.orchestrator.initHome();
      if (vm.videos.isEmpty) {
        await vm.init();
      }
      if (!mounted) return;
      setState(() {
        featuredIndex = currentHourVideoIndex;
      });
      // Suscribirse al stream de unattended SOLO si es brigadista
      if (mounted && widget.userType?.toLowerCase() == 'brigadist') {
        _subscribeToUnattended();
      }
    });

    // Suscripción a Unattended se realiza después de initHome()
  }

  /// Suscripción al Stream de emergencias Unattended en tiempo real
  void _subscribeToUnattended() {
    setState(() => _loadingUnattended = true);

    _unattendedSub = widget.orchestrator.unattendedEmergenciesStream() // ajusta el nombre si lo llamaste diferente
        .listen(
      (list) {
        if (!mounted) return;
        setState(() {
          _unattended = list;
          _loadingUnattended = false;
        });
      },
      onError: (e) {
        if (!mounted) return;
        setState(() => _loadingUnattended = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading emergencies')),
        );
      },
    );
  }

  Future<void> _onTapEmergencyCard(Map<String, dynamic> emergency) async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Attend emergency?'),
            content: const Text(
              'Do you want to attend this emergency and mark it as In Progress?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Attend'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    // Obtenemos el id del brigadista logueado (email)
    final user = widget.orchestrator.getUserData();
    final brigadistId = user?.email;

    try {
      await widget.orchestrator.attendEmergency(
        
        emergencyId: emergency['id'] as String,
        brigadistId: brigadistId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Emergency set to In Progress'),
          backgroundColor: cs.primary,
        ),
      );

      // No hace falta refrescar manualmente: el Stream se actualizará solo
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error attending emergency'),
          backgroundColor: cs.error,
        ),
      );
    }
  }

  void _navigateToNewsFeed(BuildContext context) {
    Navigator.of(context).pushNamed('/news');
  }

  void _navigateToBloodDonation(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BloodDonationPage(
          orchestrator: widget.orchestrator,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    _hourTimer?.cancel();
    _unattendedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final vm = widget.orchestrator.videoVM;
    final items = vm.videos;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ===== Barra superior =====
            Container(
              color: cs.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      notifications[currentNotificationIndex],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'All notifications',
                    onPressed: () =>
                        showAllNotificationsDialog(context, notifications),
                    icon: Icon(
                      Icons.notifications_none_rounded,
                      size: 20,
                      color: cs.onPrimary,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Emergency Stats',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmergencyAnalyticsPage(
                            orchestrator: widget.orchestrator,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.bar_chart, size: 20, color: cs.onPrimary),
                  ),
                  IconButton(
                    tooltip: 'Profile',
                    onPressed: () =>
                        showProfileMenuDialog(context, widget.onOpenProfile),
                    icon: Icon(
                      Icons.account_circle,
                      size: 20,
                      color: cs.onPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // ===== Contenido =====
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                children: [
                  Text(
                    'Hi ${widget.userName}!',
                    style: tt.headlineSmall?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ===== Sección Unattended SOLO Brigadist =====
                  if (widget.userType?.toLowerCase() == 'brigadist') ...[
                    Text(
                      'Unattended Emergencies',
                      style: tt.titleLarge?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_loadingUnattended)
                      const Center(child: CircularProgressIndicator())
                    else if (_unattended.isEmpty)
                      Text(
                        'There are no unattended emergencies right now.',
                        style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                      )
                    else
                      Column(
                        children: _unattended
                            .map(
                              (e) => _EmergencyCard(
                                emergency: e,
                                onTap: () => _onTapEmergencyCard(e),
                              ),
                            )
                            .toList(),
                      ),

                    const SizedBox(height: 24),
                  ],

                  // --- Join the Brigade (se oculta para brigadistas) ---
                  if (widget.userType?.toLowerCase() != 'brigadist') ...[
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              theme.brightness == Brightness.light ? .05 : .25,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Container(
                                  color: cs.surface,
                                  child: const RotatingImageBox(),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                20,
                                24,
                                20,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: cs.primary,
                                        child: Icon(
                                          Icons.group,
                                          color: cs.onPrimary,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Flexible(
                                        child: Text(
                                          'Join the Brigade',
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: tt.titleMedium?.copyWith(
                                            color: cs.onSurface,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Become part of the student safety team and help keep our campus secure.',
                                    style: tt.bodyMedium?.copyWith(
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: FilledButton(
                                      onPressed: () async {
                                        final connResult = await Connectivity()
                                            .checkConnectivity();
                                        if (connResult ==
                                            ConnectivityResult.none) {
                                          if (!context.mounted) return;
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const OfflineInfoPage(),
                                            ),
                                          );
                                          return;
                                        }

                                        bool hasInternet = false;
                                        try {
                                          final uri = Uri.parse(
                                            'https://clients3.google.com/generate_204',
                                          );
                                          final resp = await http
                                              .get(uri)
                                              .timeout(
                                                const Duration(seconds: 3),
                                              );
                                          if (resp.statusCode == 204 ||
                                              resp.statusCode == 200) {
                                            hasInternet = true;
                                          }
                                        } catch (e) {
                                          hasInternet = false;
                                        }

                                        if (!hasInternet) {
                                          if (!context.mounted) return;
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const OfflineInfoPage(),
                                            ),
                                          );
                                          return;
                                        }

                                        final url = Uri.parse(
                                          'https://www.instagram.com/beuniandes/',
                                        );

                                        try {
                                          final launched = await launchUrl(
                                            url,
                                            mode:
                                                LaunchMode.externalApplication,
                                          );

                                          if (!launched) {
                                            if (!context.mounted) return;
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              SnackBar(
                                                content: const Text(
                                                  'Could not open Instagram link',
                                                ),
                                                backgroundColor: cs.error,
                                                behavior:
                                                    SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: const Text(
                                                'Error opening Instagram',
                                              ),
                                              backgroundColor: cs.error,
                                              behavior:
                                                  SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      },
                                      child: const Text('Learn More'),
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
                  ],

                  // --- Learn on Your Own (hidden for brigadists) ---
                  if (widget.userType?.toLowerCase() != 'brigadist') ...[
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              theme.brightness == Brightness.light ? .05 : .25,
                            ),
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
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: cs.secondary,
                                child: Icon(
                                  Icons.menu_book_rounded,
                                  color: cs.onSecondary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Learn on Your Own',
                                style: tt.titleMedium?.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Watch training videos and safety guides at your own pace.',
                            style: tt.bodySmall?.copyWith(color: cs.onSurface),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 280,
                            child: items.isEmpty
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : Builder(
                                    builder: (context) {
                                      final sortedItems = [...items]
                                        ..sort(
                                          (a, b) => b.views.compareTo(a.views),
                                        );
                                      return ListView.separated(
                                        scrollDirection: Axis.horizontal,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        itemCount: sortedItems.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(width: 16),
                                        itemBuilder: (context, i) {
                                          final v = sortedItems[i];
                                          final isFeatured =
                                              i ==
                                              (featuredIndex %
                                                  sortedItems.length);
                                          return VideoCard(
                                            video: v,
                                            isFeatured: isFeatured,
                                            onTap: () => widget.orchestrator
                                                .openVideoDetails(context, v),
                                          );
                                        },
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: widget.onNavigateToVideos,
                            child: const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('View All Videos'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- News Section ---
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              theme.brightness == Brightness.light ? .05 : .25,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: cs.tertiary,
                                child: Icon(
                                  Icons.article_rounded,
                                  color: cs.onTertiary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Campus News',
                                style: tt.titleMedium?.copyWith(
                                  color: cs.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Stay updated with the latest campus news and announcements.',
                            style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => _navigateToNewsFeed(context),
                              icon: const Icon(Icons.article),
                              label: const Text('Read Latest News'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => _navigateToBloodDonation(context),
                              icon: const Icon(Icons.favorite),
                              label:
                                  const Text('Blood Donation Information'),
                              style: FilledButton.styleFrom(
                                backgroundColor: cs.error,
                                foregroundColor: cs.onError,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tarjeta individual de emergencia
class _EmergencyCard extends StatelessWidget {
  final Map<String, dynamic> emergency;
  final VoidCallback onTap;

  const _EmergencyCard({required this.emergency, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final type = (emergency['type'] ?? 'Medical').toString();
    final location = (emergency['location'] ?? 'Unknown').toString();
    final minutes = (emergency['secondsResponse'] ?? emergency['distance'] ?? 0)
        .toString();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                theme.brightness == Brightness.light ? .04 : .25,
              ),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: tt.titleMedium?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Location: $location',
                    style: tt.bodySmall?.copyWith(color: cs.onSurface),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$minutes s',
                  style: tt.titleMedium?.copyWith(
                    color: cs.secondary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'away',
                  style: tt.bodySmall?.copyWith(color: cs.onSurface),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/* =================== Modales reutilizables =================== */

Future<void> showProfileMenuDialog(
  BuildContext context,
  VoidCallback? onOpenProfile,
) {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  final tt = theme.textTheme;

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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              decoration: BoxDecoration(
                color: cs.primary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: cs.onPrimary.withOpacity(.2),
                    child: Icon(Icons.person, color: cs.onPrimary, size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Profile & Settings',
                    style: tt.titleMedium?.copyWith(color: cs.onPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage your account and preferences',
                    style: tt.bodySmall?.copyWith(color: cs.onPrimary),
                  ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: cs.primaryContainer,
                        child: Icon(
                          Icons.person_outline,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Profile Settings',
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: cs.onSurface),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: InkWell(
                onTap: () async {
                  Navigator.pop(ctx);
                  await AuthService.instance.logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) =>
                          const AuthGate(childWhenAuthed: NavShell()),
                    ),
                    (_) => false,
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: cs.errorContainer,
                        child: Icon(Icons.logout, color: cs.onErrorContainer),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Log out',
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
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
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  final tt = theme.textTheme;

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
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  border: Border(bottom: BorderSide(color: theme.dividerColor)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: cs.primary,
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: cs.onPrimary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'All Notifications',
                      style: tt.titleMedium?.copyWith(
                        color: cs.onSurface,
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
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.dividerColor),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(
                                    theme.brightness == Brightness.light
                                        ? .03
                                        : .2,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: cs.primary,
                                  child: Icon(
                                    Icons.notifications,
                                    size: 14,
                                    color: cs.onPrimary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    n,
                                    style: tt.bodyMedium?.copyWith(
                                      color: cs.onSurface,
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
