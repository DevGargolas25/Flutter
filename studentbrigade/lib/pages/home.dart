import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final String userName;
  const HomePage({super.key, this.userName = 'John'});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const _AnnouncementBanner(
            text: 'Campus safety drill scheduled for tomorrow at 2 PM',
          ),
          const SizedBox(height: 16),
          _GreetingHeader(name: userName),
          const SizedBox(height: 12),
          const _JoinBrigadeCard(),
          const SizedBox(height: 16),
          const _LearnOnYourOwnSection(),
        ],
      ),
    );
  }
}

/* ========================= ESTILOS ========================= */
const _mint = Color(0xFF61C0B6);
const _mintSoft = Color(0xFFA9E3DD);
const _cardBg = Color(0xFFEFF8F7);

/* =================== BANNER DE ANUNCIO ==================== */
class _AnnouncementBanner extends StatelessWidget {
  final String text;
  const _AnnouncementBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _mintSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.campaign_rounded, size: 18, color: Colors.black87),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          IconButton(
            tooltip: 'Profile',
            onPressed: () {},
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
    );
  }
}

/* ========================= SALUDO ========================= */
class _GreetingHeader extends StatelessWidget {
  final String name;
  const _GreetingHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    return Text(
      'Hi $name!',
      style: Theme.of(context)
          .textTheme
          .headlineMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

/* ==================== TARJETA JOIN ======================== */
class _JoinBrigadeCard extends StatelessWidget {
  const _JoinBrigadeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFFBEE8E2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.health_and_safety_rounded, size: 44),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Join the Brigade',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 6),
                Text(
                  'Become part of the student safety team and help keep our campus secure.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.black87),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonal(
                    onPressed: () {},
                    child: const Text('Learn More'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ==================== SECCIÓN LEARN ======================= */
class _LearnOnYourOwnSection extends StatelessWidget {
  const _LearnOnYourOwnSection();

  @override
  Widget build(BuildContext context) {
    final captionStyle =
    Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.menu_book_rounded),
              const SizedBox(width: 8),
              Text(
                'Learn on Your Own',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Watch training videos and safety guides at your own pace.',
            style: captionStyle,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 8),
              itemCount: _demoVideos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _VideoCard(video: _demoVideos[i]),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: () {}, child: const Text('View All Videos')),
        ],
      ),
    );
  }
}

/* ===================== TARJETA VIDEO ====================== */
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

const _demoVideos = <_VideoInfo>[
  _VideoInfo(
    title: 'Campus Emergency Procedures',
    tag: 'Emergency',
    duration: '5:24',
    views: '2.3k views',
    featured: true,
  ),
  _VideoInfo(
    title: 'First Aid Basics for Students',
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
    final cardW = MediaQuery.of(context).size.width * 0.68;

    return Container(
      width: cardW.clamp(260, 320),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail placeholder
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                colors: [Color(0xFFCFEDEA), Color(0xFF9FDAD4)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: const Center(
              child: Icon(Icons.play_circle_fill, size: 54, color: Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                label: Text(video.tag),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              if (video.featured)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7F4),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF9FDAD4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.teal),
                      SizedBox(width: 4),
                      Text('Now Featured',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            video.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _pill(icon: Icons.schedule, text: video.duration),
              const SizedBox(width: 8),
              _pill(icon: Icons.visibility_outlined, text: video.views),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
