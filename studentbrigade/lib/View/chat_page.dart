import 'package:flutter/material.dart';
import 'chat_screen.dart';

class ChatbotsScreen extends StatelessWidget {
  static const routeName = '/chatbots';
  const ChatbotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header + buscador (usa primary/onPrimary)
            Container(
              width: double.infinity,
              color: cs.primary,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Messages',
                    style: tt.titleLarge?.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.inputDecorationTheme.fillColor ??
                          cs.surface,
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: theme.dividerColor),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: cs.onSurface.withOpacity(.6)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Search conversations...',
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurface.withOpacity(.55),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Lista de asistentes
            Expanded(
              child: ListView(
                children: [
                  _ChatbotTile(
                    title: 'Brigade Assistant',
                    subtitle:
                    'The main assembly points are: Main Campus: Front park...',
                    time: '10:32 AM',
                    unread: 2,
                    // color de “marca” del avatar (se mezcla con el tema)
                    accent: const Color(0xFF64C3C5),
                    icon: Icons.smart_toy_outlined,
                    onTap: () =>
                        Navigator.pushNamed(context, ChatScreen.routeName),
                  ),
                  Divider(height: 1, indent: 70, endIndent: 16, color: theme.dividerColor),

                  _ChatbotTile(
                    title: 'Brigade Team',
                    subtitle:
                    'Meeting tonight at 7 PM in room 203. Please confirm y...',
                    time: '9:45 AM',
                    unread: 0,
                    accent: const Color(0xFF58A57B),
                    icon: Icons.groups_rounded,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Abrir chat Brigade Team')),
                      );
                    },
                  ),
                  Divider(height: 1, indent: 70, endIndent: 16, color: theme.dividerColor),

                  _ChatbotTile(
                    title: 'Brigade Alerts',
                    subtitle:
                    'Weather alert: Strong winds expected this afternoon. St...',
                    time: 'Yesterday',
                    unread: 1,
                    accent: const Color(0xFFE29375),
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Abrir chat Brigade Alerts')),
                      );
                    },
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

class _ChatbotTile extends StatelessWidget {
  final String title, subtitle, time;
  final int unread;
  final Color accent; // color “de marca” del avatar
  final IconData icon;
  final VoidCallback onTap;

  const _ChatbotTile({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.unread,
    required this.accent,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final baseText = cs.onSurface.withOpacity(.7);
    final subtleText = cs.onSurface.withOpacity(.55);

    return Material(
      color: theme.cardColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Avatar usa el “accent” sobre el tema actual
              CircleAvatar(
                radius: 22,
                backgroundColor: accent.withOpacity(.2),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),

              // Texto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall?.copyWith(color: subtleText),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Hora + badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(time, style: tt.labelSmall?.copyWith(color: subtleText)),
                  const SizedBox(height: 6),
                  if (unread > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (accent.withOpacity(.18)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accent.withOpacity(.35)),
                      ),
                      child: Text(
                        '$unread',
                        style: tt.labelMedium?.copyWith(
                          color: accent.darkenOnTheme(context, fallback: cs.primary),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// === Helpers opcionales ===
// Un pequeño helper para ajustar el contraste del “accent” en dark mode.
extension _AccentHelpers on Color {
  Color darkenOnTheme(BuildContext context, {required Color fallback}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // si es muy claro y estamos en light, usa el propio color;
    // si es dark, baja un poco el valor para ganar contraste.
    if (!isDark) return this;
    final hsl = HSLColor.fromColor(this);
    final darker = hsl.withLightness((hsl.lightness * 0.7).clamp(0.0, 1.0));
    return darker.toColor();
  }
}
