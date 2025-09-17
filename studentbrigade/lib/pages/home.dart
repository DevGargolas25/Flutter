import 'package:flutter/material.dart';
import './widgets/rotating_image_box.dart';


class HomePage extends StatelessWidget {
  final String userName;
  const HomePage({super.key, this.userName = 'John'});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            AnnouncementBanner(
              text: 'Campus safety drill scheduled for tomorrow at 2 PM',
            ),
            const SizedBox(height: 16),
            Text(
              'Hi $userName!',
              style: tt.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _JoinBrigadeCard(),
            const SizedBox(height: 16),
            _LearnOnYourOwnSection(),
          ],
        ),
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

    );
  }
}

/* ------------------------ Banner dinámico ------------------------ */
class AnnouncementBanner extends StatefulWidget {
  final String text;
  const AnnouncementBanner({super.key, required this.text});

  @override
  State<AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends State<AnnouncementBanner> {
  bool _visible = true;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    if (!_visible) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withOpacity(.35),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.campaign_rounded, size: 20, color: cs.onSurface),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.text, // ahora se accede con widget.text
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: () {
              // Aquí podría abrir notificaciones
            },
            icon: Icon(Icons.notifications_none_rounded, color: cs.onSurface),
            visualDensity: VisualDensity.compact,
            iconSize: 20,
            splashRadius: 18,
            tooltip: 'Notifications',
          ),
          IconButton(
            onPressed: () {
              // Cierra el banner
              setState(() {
                _visible = false;
              });
            },
            icon: Icon(Icons.close, color: cs.onSurface),
            visualDensity: VisualDensity.compact,
            iconSize: 20,
            splashRadius: 18,
            tooltip: 'Close',
          ),
        ],
      ),
    );
  }
}


/* ---------------------- Tarjeta “Join the Brigade” ---------------------- */
class _JoinBrigadeCard extends StatelessWidget {
  const _JoinBrigadeCard();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const RotatingImageBox(),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Join the Brigade', style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    'Become part of the student safety team and help keep our campus secure.',
                    style: tt.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    onPressed: () {},
                    child: const Text('Learn More'),
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

/* ------------------- Sección “Learn on Your Own” ------------------- */
class _LearnOnYourOwnSection extends StatelessWidget {
  const _LearnOnYourOwnSection();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.menu_book_rounded, color: cs.onSurface),
              const SizedBox(width: 8),
              Text('Learn on Your Own', style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            ]),
            const SizedBox(height: 6),
            Text('Watch training videos and safety guides at your own pace.', style: tt.bodyMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 210,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _videos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => _VideoCard(video: _videos[i]),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () {}, child: const Text('View All Videos')),
          ],
        ),
      ),
    );
  }
}

/* ------------------------- Video card + data ------------------------- */
class _VideoInfo {
  final String title;
  final String tag;
  final String duration;
  final String views;
  final bool featured;
  const _VideoInfo({
    required this.title,
    required this.tag,
    required this.duration,
    required this.views,
    this.featured = false,
  });
}

const _videos = <_VideoInfo>[
  _VideoInfo(
    title: 'Campus Emergency Procedures',
    tag: 'Emergency',
    duration: '5:24',
    views: '2.3k views',
    featured: true,
  ),
  _VideoInfo(
    title: 'First Aid Basics',
    tag: 'Medical',
    duration: '8:15',
    views: '1.8k views',
  ),
  _VideoInfo(
    title: 'Evacuation & Fire Drills',
    tag: 'Safety',
    duration: '6:02',
    views: '1.2k views',
  ),
];

class _VideoCard extends StatelessWidget {
  final _VideoInfo video;
  const _VideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final width = MediaQuery.of(context).size.width * 0.68;

    return Container(
      width: width.clamp(260, 320),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.secondaryContainer.withOpacity(.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail “placeholder” con gradiente de tu primario
          Container(
            height: 110,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                colors: [cs.primary.withOpacity(.85), cs.secondary.withOpacity(.85)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: const Center(child: Icon(Icons.play_circle_fill, size: 52, color: Colors.white)),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                label: Text(video.tag),
                // hereda ChipTheme de tu tema
              ),
              if (video.featured)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer.withOpacity(.35),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: cs.secondaryContainer),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 14, color: cs.primary),
                      const SizedBox(width: 4),
                      Text('Now Featured', style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(video.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Row(
            children: [
              _pill(context, icon: Icons.schedule, text: video.duration),
              const SizedBox(width: 8),
              _pill(context, icon: Icons.visibility_outlined, text: video.views),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, {required IconData icon, required String text}) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(.4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: cs.onSurface),
        const SizedBox(width: 4),
        Text(text, style: tt.labelSmall),
      ]),
    );
  }
}
