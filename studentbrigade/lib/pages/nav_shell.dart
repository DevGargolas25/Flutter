import 'package:flutter/material.dart';
import 'home.dart';
import 'profile_page.dart';
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
    Chatbotscreen(),
    _DummyPage(title: 'Map'),  // Placeholder for MapPage
    VideoScreen(),
    ProfilePage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _navigateToProfile(),
            icon: const Icon(Icons.account_circle),
            tooltip: 'Profile',
          ),
        ],
      ),
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
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _NavItem(
                  icon: Icons.home,
                  label: 'Home',
                  selected: _index == 0,
                  onTap: () => setState(() => _index = 0),
                ),
                _NavItem(
                  icon: Icons.chat_bubble,
                  label: 'Chat',
                  selected: _index == 1,
                  onTap: () => setState(() => _index = 1),
                ),

                // ✅ Espacio para el FAB - más ancho para mejor separación
                const SizedBox(width: 60),

                _NavItem(
                  icon: Icons.map,
                  label: 'Map',
                  selected: _index == 2,
                  onTap: () => setState(() => _index = 2),
                ),
                _NavItem(
                  icon: Icons.play_circle_filled,
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

  // Method to navigate to profile page
  void _navigateToProfile() {
    _showProfileModal();
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

  void _showProfileModal() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              // Header con fondo turquesa
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF7DD3C0), // Color turquesa de tu imagen
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    // Botón cerrar
                    Align(
                      alignment: Alignment.topRight,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    // Ícono de perfil
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Título
                    const Text(
                      'Profile & Settings',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Subtítulo
                    const Text(
                      'Manage your account and preferences',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Contenido del modal
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Profile Settings Card
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
                              const Icon(
                                Icons.person_outline,
                                size: 30,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Profile Settings',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Update personal info and emergency contacts',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
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
                          color: const Color(0xFFE8F5F3), // Verde claro
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Keep your profile updated for better emergency response.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
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
