import 'package:flutter/material.dart';
import 'home.dart';
import 'profile_page.dart';
import 'chat_page.dart';
import 'videos_screen.dart';
import 'emergency/sos_dialog.dart';

class NavShell extends StatefulWidget {
  const NavShell({super.key});
  @override
  State<NavShell> createState() => _NavShellState();
}

class _NavShellState extends State<NavShell> {
  int _index = 0;

  // Páginas reales/placeholders
  final _pages = const [
    HomePage(),
    ChatbotsScreen(),
    _DummyPage(title: 'Map'),
    VideosScreen(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],

      // Bottom Navigation Bar with integrated SOS button
      bottomNavigationBar: Container(
        height: 60, // Further reduced height
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _NavItem(
              icon: Icons.home_outlined,
              selectedIcon: Icons.home,
              label: 'Home',
              selected: _index == 0,
              onTap: () => setState(() => _index = 0),
            ),
            _NavItem(
              icon: Icons.chat_bubble_outline,
              selectedIcon: Icons.chat_bubble,
              label: 'Chat',
              selected: _index == 1,
              onTap: () => setState(() => _index = 1),
            ),
            // SOS Button in center
            _SOSButton(onTap: () => SosDialog.show(context)),
            _NavItem(
              icon: Icons.map_outlined,
              selectedIcon: Icons.map,
              label: 'Map',
              selected: _index == 2,
              onTap: () => setState(() => _index = 2),
            ),
            _NavItem(
              icon: Icons.play_circle_outline,
              selectedIcon: Icons.play_circle_filled,
              label: 'Videos',
              selected: _index == 3,
              onTap: () => setState(() => _index = 3),
            ),
          ],
        ),
      ),
    );
  }
}
  

/* ======================= SOS Button ======================= */
class _SOSButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SOSButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36, // Much smaller
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFE53E3E),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 18, // Smaller icon
            ),
          ),
          const Text(
            'SOS',
            style: TextStyle(
              fontSize: 7, // Very small text
              color: Color(0xFFE53E3E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/* ======================= Item del Bottom Nav ======================= */
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData? selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Colores sutiles como en tus capturas
    final baseColor = Colors.grey.shade500;
    final selColor = cs.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4), // Reduced padding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? (selectedIcon ?? icon) : icon,
              size: 22, // Smaller icons
              color: selected ? selColor : baseColor,
            ),
            const SizedBox(height: 2), // Reduced spacing
            Text(
              label,
              style: TextStyle(
                fontSize: 9, // Smaller text
                color: selected ? selColor : baseColor,
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