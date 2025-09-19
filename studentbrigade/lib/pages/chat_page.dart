import 'package:flutter/material.dart';
import 'chat_screen.dart';

class ChatbotsScreen extends StatelessWidget {
  static const routeName = '/chatbots';
  const ChatbotsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final headerColor = const Color(0xFF62B6B7);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header + buscador
            Container(
              width: double.infinity,
              color: headerColor,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Messages',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: Colors.black54),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Search conversations...',
                            style: TextStyle(
                              color: Colors.black45,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // Assistants
            Expanded(
              child: ListView(
                children: [
                  _ChatbotTile(
                    title: 'Brigade Assistant',
                    subtitle:
                        'The main assembly points are: Main Campus: Front park...',
                    time: '10:32 AM',
                    unread: 2,
                    avatarColor: const Color(0xFF64C3C5),
                    icon: Icons.smart_toy_outlined,
                    onTap: () =>
                        Navigator.pushNamed(context, ChatScreen.routeName),
                  ),
                  const Divider(height: 1, indent: 70, endIndent: 16),
                  // ---- Brigade Team ----
                  _ChatbotTile(
                    title: 'Brigade Team',
                    subtitle:
                        'Meeting tonight at 7 PM in room 203. Please confirm y...',
                    time: '9:45 AM',
                    unread: 0,
                    avatarColor: const Color(0xFF58A57B),
                    icon: Icons.groups_rounded,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Abrir chat Brigade Team'),
                        ),
                      );
                    },
                  ),

                  const Divider(height: 1, indent: 70, endIndent: 16),
                  // ---- Brigade Alerts ----
                  _ChatbotTile(
                    title: 'Brigade Alerts',
                    subtitle:
                        'Weather alert: Strong winds expected this afternoon. St...',
                    time: 'Yesterday',
                    unread: 1,
                    avatarColor: const Color(0xFFE29375),
                    icon: Icons.chat_bubble_outline_rounded,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Abrir chat Brigade Alerts'),
                        ),
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
  final Color avatarColor;
  final IconData icon;
  final VoidCallback onTap;

  const _ChatbotTile({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.unread,
    required this.avatarColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: avatarColor.withOpacity(.2),
                child: Icon(icon, color: avatarColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    time,
                    style: const TextStyle(color: Colors.black45, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  if (unread > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF63C0C2).withOpacity(.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$unread',
                        style: const TextStyle(
                          color: Color(0xFF2D8E90),
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
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
