import 'package:flutter/material.dart';

// import Views
import 'home.dart';
import 'profile_page.dart';
import 'chat_page.dart';
import 'videos_screen.dart';
import 'map_page.dart';
import 'emergency/sos_dialog.dart';
import 'widgets/connectivity_banner.dart';

// import Orchestrator
import '../VM/Orchestrator.dart';

class NavShell extends StatefulWidget {
  const NavShell({super.key});
  @override
  State<NavShell> createState() => _NavShellState();
}

class _NavShellState extends State<NavShell> {
  int _index = 0;
  late final Orchestrator _orchestrator;

  @override
  void initState() {
    super.initState();
    _orchestrator = Orchestrator();
    _orchestrator.addListener(_onOrchestratorChanged);
  }

  void _onOrchestratorChanged() {
    if (_orchestrator.currentPageIndex != _index) {
      setState(() => _index = _orchestrator.currentPageIndex);
    }
  }

  @override
  void dispose() {
    _orchestrator.removeListener(_onOrchestratorChanged);
    super.dispose();
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return HomePage(
          orchestrator: _orchestrator,
          onOpenProfile: () => _orchestrator.navigateToProfile(),
        );
      case 1:
        return ChatView(orchestrator: _orchestrator);
      case 2:
        return MapPage(orchestrator: _orchestrator);
      case 3:
        return VideosPage(orchestrator: _orchestrator);
      case 4:
        return ProfilePage(orchestrator: _orchestrator);
      default:
        return HomePage(orchestrator: _orchestrator);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return ConnectivityBanner(
      child: Scaffold(
        body: _getPage(_index),

        // Bottom Navigation Bar con tema dinámico
        bottomNavigationBar: Container(
          height: 60,
          decoration: BoxDecoration(
            color: theme.bottomNavigationBarTheme.backgroundColor ?? cs.surface,
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withOpacity(
                  theme.brightness == Brightness.light ? .06 : .28,
                ),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
            border: Border(top: BorderSide(color: theme.dividerColor)),
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
                onTap: () => _orchestrator.navigateToPage(0),
              ),
              _NavItem(
                icon: Icons.chat_bubble_outline,
                selectedIcon: Icons.chat_bubble,
                label: 'Chat',
                selected: _index == 1,
                onTap: () => _orchestrator.navigateToPage(1),
              ),
              // SOS Button in center
              _SOSButton(onTap: () => SosDialog.show(context, _orchestrator)),
              _NavItem(
                icon: Icons.map_outlined,
                selectedIcon: Icons.map,
                label: 'Map',
                selected: _index == 2,
                onTap: () => _orchestrator.navigateToPage(2),
              ),
              _NavItem(
                icon: Icons.play_circle_outline,
                selectedIcon: Icons.play_circle_filled,
                label: 'Videos',
                selected: _index == 3,
                onTap: () => _orchestrator.navigateToPage(3),
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
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.error, // usa color de error del tema
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: cs.onError, // contraste correcto
              size: 18,
            ),
          ),
          Text(
            'SOS',
            style: TextStyle(
              fontSize: 9,
              color: cs.error,
              fontWeight: FontWeight.w600,
              height: 1.0,
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final baseColor =
        theme.bottomNavigationBarTheme.unselectedItemColor ??
        cs.onSurface.withOpacity(.6);
    final selColor =
        theme.bottomNavigationBarTheme.selectedItemColor ?? cs.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? (selectedIcon ?? icon) : icon,
              size: 22,
              color: selected ? selColor : baseColor,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
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
