import 'package:flutter/material.dart';
import './widgets/message.dart';
import './widgets/message_bubble.dart';

class ChatScreen extends StatelessWidget {
  static const routeName = '/chat';
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final headerColor = const Color(0xFF62B6B7);

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
            // Header tipo appbar
            Container(
              color: headerColor,
              padding: const EdgeInsets.fromLTRB(8, 8, 12, 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withOpacity(.25),
                    child: const Icon(
                      Icons.smart_toy_outlined,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Brigade Assistant',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Always here to help',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Lista de mensajes
            const SizedBox(height: 6),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                itemCount: messages.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (_, i) => MessageBubble(msg: messages[i]),
              ),
            ),

            // Barra inferior (decorativa)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F3F4),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.centerLeft,
                      child: const Text(
                        'Type a message…',
                        style: TextStyle(color: Colors.black45, fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.send_rounded, color: Colors.black26),
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
