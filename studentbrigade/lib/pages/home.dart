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
            const _JoinBrigadeCard(),
            const SizedBox(height: 16),
            const _LearnOnYourOwnSection(),
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
              widget.text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.notifications_none_rounded, color: cs.onSurface),
            visualDensity: VisualDensity.compact,
            iconSize: 20,
            splashRadius: 18,
            tooltip: 'Notifications',
          ),
          IconButton(
            onPressed: () {
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

/* ---------------------- Tarjeta "Join the Brigade" ---------------------- */
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

/* ------------------- Sección "Learn on Your Own" ------------------- */
class _LearnOnYourOwnSection extends StatelessWidget {
  const _LearnOnYourOwnSection();

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          screenWidth * 0.04,
          screenWidth * 0.04, 
          screenWidth * 0.02,
          screenWidth * 0.04
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.menu_book_rounded, color: cs.onSurface),
              SizedBox(width: screenWidth * 0.02),
              Flexible(
                child: Text(
                  'Learn on Your Own', 
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
            SizedBox(height: screenWidth * 0.015),
            Text(
              'Watch training videos and safety guides at your own pace.', 
              style: tt.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: screenWidth * 0.03),
            SizedBox(
              height: screenWidth * 0.5,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.01),
                itemCount: _videos.length,
                separatorBuilder: (_, __) => SizedBox(width: screenWidth * 0.03),
                itemBuilder: (_, i) => _VideoCard(video: _videos[i]),
              ),
            ),
            SizedBox(height: screenWidth * 0.02),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {}, 
                child: const Text('View All Videos'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ✅ UNA SOLA DEFINICIÓN DE _VideoCard ------------------------- */
class _VideoCard extends StatelessWidget {
  final _VideoInfo video;
  const _VideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    
    final cardWidth = screenWidth < 600 
        ? screenWidth * 0.6
        : screenWidth * 0.45;

    return Container(
      width: cardWidth,
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(screenWidth * 0.045),
        border: Border.all(color: cs.secondaryContainer.withOpacity(.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail adaptable
          Container(
            height: cardWidth * 0.4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(screenWidth * 0.04),
              gradient: LinearGradient(
                colors: [cs.primary.withOpacity(.85), cs.secondary.withOpacity(.85)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.play_circle_fill, 
                size: cardWidth * 0.2,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: screenWidth * 0.02),
          
          // Chips adaptables
          LayoutBuilder(
            builder: (context, constraints) {
              return Wrap(
                spacing: screenWidth * 0.02,
                runSpacing: screenWidth * 0.015,
                children: [
                  _AdaptiveChip(
                    label: video.tag,
                    maxWidth: constraints.maxWidth * 0.5,
                  ),
                  if (video.featured)
                    _AdaptiveChip(
                      label: 'Featured',
                      icon: Icons.star,
                      maxWidth: constraints.maxWidth * 0.45,
                      isSpecial: true,
                    ),
                ],
              );
            },
          ),
          
          SizedBox(height: screenWidth * 0.01),
          
          // Título adaptable
          Flexible(
            child: Text(
              video.title, 
              maxLines: 2, 
              overflow: TextOverflow.ellipsis, 
              style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          
          SizedBox(height: screenWidth * 0.015),
          
          // Pills adaptables
          Flexible(
            child: Row(
              children: [
                Expanded(
                  child: _pill(context, icon: Icons.schedule, text: video.duration),
                ),
                SizedBox(width: screenWidth * 0.02),
                Expanded(
                  child: _pill(context, icon: Icons.visibility_outlined, text: video.views),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, {required IconData icon, required String text}) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.02,
        vertical: screenWidth * 0.015,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceVariant.withOpacity(.4),
        borderRadius: BorderRadius.circular(screenWidth * 0.025),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: screenWidth * 0.035, color: cs.onSurface),
          SizedBox(width: screenWidth * 0.01),
          Flexible(
            child: Text(
              text, 
              style: tt.labelSmall,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/* ✅ UNA SOLA DEFINICIÓN DE _AdaptiveChip ------------------------- */
class _AdaptiveChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final double maxWidth;
  final bool isSpecial;

  const _AdaptiveChip({
    required this.label,
    required this.maxWidth,
    this.icon,
    this.isSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    if (isSpecial) {
      return Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.02,
          vertical: screenWidth * 0.01,
        ),
        decoration: BoxDecoration(
          color: cs.tertiaryContainer.withOpacity(.35),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: cs.secondaryContainer),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: screenWidth * 0.03, color: cs.primary),
              SizedBox(width: screenWidth * 0.005),
            ],
            Flexible(
              child: Text(
                label,
                style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Chip(
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/* ✅ DATOS AL FINAL DEL ARCHIVO ------------------------- */
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