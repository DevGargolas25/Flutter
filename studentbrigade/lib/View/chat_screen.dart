import 'package:flutter/material.dart';
import 'widgets/message.dart';
import 'widgets/message_bubble.dart';

class ChatScreen extends StatelessWidget {
  static const routeName = '/chat';
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    // Mensajes de ejemplo (como tu captura)
    const messages = <Message>[
      Message(
        fromBot: true,
        time: '10:30 AM',
        text:
        "Hello! I'm your Student Brigade assistant.\nHow can I help you today?",
      ),
      Message(
        fromBot: false,
        time: '10:31 AM',
        text: 'What should I do in case of a fire emergency?',
      ),
      Message(
        fromBot: true,
        time: '10:31 AM',
        text:
        'In case of fire:\n\n1. Stay calm and alert others\n2. Use the nearest exit (never elevators)\n3. Feel doors before opening\n4. Stay low if there\'s smoke\n5. Meet at the designated assembly point\n6. Call emergency services: 911\n\nDo you need more specific information about fire safety?',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header tipo AppBar con colores del tema
            Container(
              color: cs.primary,
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 10),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: cs.onPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: cs.onPrimary.withOpacity(.25),
                    child: Icon(Icons.smart_toy_outlined, color: cs.onPrimary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Brigade Assistant',
                          style: tt.titleMedium?.copyWith(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Always here to help',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onPrimary.withOpacity(.7),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Lista de mensajes
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                itemCount: messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) => MessageBubble(msg: messages[i]),
              ),
            ),

            // Barra inferior (placeholder de input) usando el tema
            Container(
              color: theme.cardColor,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.inputDecorationTheme.fillColor ??
                            cs.surfaceVariant,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Type a message…',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurface.withOpacity(.55),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Icons.send_rounded, color: cs.onSurface.withOpacity(.35)),
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

