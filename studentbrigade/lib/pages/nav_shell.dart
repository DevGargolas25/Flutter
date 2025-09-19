import 'package:flutter/material.dart';
import 'home.dart';
import 'chat_page.dart';
import 'videos_screen.dart';

class NavShell extends StatefulWidget {
  const NavShell({super.key});
  @override
  State<NavShell> createState() => _NavShellState();
}

class _NavShellState extends State<NavShell> {
  int _index = 0;

  // Reemplaza _DummyPage por tus páginas reales si ya las tienes
  final _pages = const [
    HomePage(),
    ChatbotsScreen(),
    _DummyPage(title: 'Map'),
    VideosScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],

      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSos(context),
        child: const Icon(Icons.warning_amber_rounded),
      ),

      bottomNavigationBar: BottomAppBar(
        elevation: 0,
        shape: const CircularNotchedRectangle(),
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Container(
            height: 78,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  label: 'Home',
                  selected: _index == 0,
                  onTap: () => setState(() => _index = 0),
                ),
                _NavItem(
                  icon: Icons.chat_bubble_outline,
                  label: 'Chat',
                  selected: _index == 1,
                  onTap: () => setState(() => _index = 1),
                ),

                // ✅ Espacio para el FAB - más ancho para mejor separación
                const SizedBox(width: 60),

                _NavItem(
                  icon: Icons.map_outlined,
                  label: 'Map',
                  selected: _index == 2,
                  onTap: () => setState(() => _index = 2),
                ),
                _NavItem(
                  icon: Icons.play_circle_outline,
                  label: 'Videos',
                  selected: _index == 3,
                  onTap: () => setState(() => _index = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSos(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Emergency Assistance',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            ListTile(
              leading: const Icon(Icons.campaign_rounded),
              title: const Text('Send Emergency Alert'),
              subtitle: const Text('Alert campus security and brigade members'),
              onTap: () {}, // TODO
            ),
            ListTile(
              leading: const Icon(Icons.support_agent_rounded),
              title: const Text('Contact Brigade'),
              subtitle: const Text('Connect with nearest brigade member'),
              onTap: () {}, // TODO
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/* ======================= Item del Bottom Nav ======================= */
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // ✅ Colores más sutiles como en la imagen
    final baseColor = Colors.grey.shade500;
    final selIcon = cs.primary;
    final selText = cs.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 24, // ✅ Iconos más grandes como en la imagen
              color: selected ? selIcon : baseColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11, // ✅ Texto más pequeño
                color: selected ? selText : baseColor,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ======================= Páginas de ejemplo ======================= */
class _DummyPage extends StatelessWidget {
  final String title;
  const _DummyPage({required this.title});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title page', style: tt.headlineMedium)),
    );
  }
}
