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
      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _navigateToProfile,
            icon: const Icon(Icons.account_circle),
            tooltip: 'Profile',
          ),
        ],
      ),

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

  // Abre el modal de perfil y navega a la pestaña ProfilePage si el usuario toca la tarjeta
  void _navigateToProfile() {
    _showProfileModal();
  }

  void _showProfileModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Header con fondo turquesa
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFF7DD3C0),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 20, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: Icon(Icons.person, size: 30, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Profile & Settings',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Manage your account and preferences',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                  ],
                ),
              ),

              // Contenido del modal
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context); // Cerrar modal
                          setState(() {
                            _index = 4; // Ir a ProfilePage
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline, size: 30, color: Colors.grey),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'Profile Settings',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Update personal info and emergency contacts',
                                      style: TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Texto informativo
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5F3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Keep your profile updated for better emergency response.',
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ],
          ),
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