// lib/pages/emergency/emergency_chat_page.dart
import 'package:flutter/material.dart';

class EmergencyChatPage extends StatelessWidget {
  const EmergencyChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Emergency Active', style: tt.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
            Text('Help is on the way', style: tt.bodySmall?.copyWith(color: Colors.white70)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Row(children: [
              Icon(Icons.circle, size: 10, color: Colors.lightGreenAccent),
              SizedBox(width: 6),
              Text('Connected'),
              SizedBox(width: 12),
            ]),
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            color: cs.secondaryContainer.withOpacity(.35),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Wrap(
              spacing: 12,
              children: const [
                _ChipTab('Brigadist'),
                _ChipTab('Medical'),
                _ChipTab('Assistant'),
                _ChipTab('Location'),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: const [
                _ContactCard(name: 'Sarah Martinez', subtitle: 'Available · 2 min away'),
                SizedBox(height: 8),
                _Bubble(text: "Emergency received! I'm Sarah from the Brigade Team. Are you injured?"),
                SizedBox(height: 6),
                _Bubble(text: "I'm currently 2 minutes away from your location. Stay calm."),
              ],
            ),
          ),
          const _Composer(),
        ],
      ),
    );
  }
}

class _ChipTab extends StatelessWidget {
  final String text;
  const _ChipTab(this.text);
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Chip(
      label: Text(text),
      backgroundColor: cs.primary.withOpacity(.12),
      shape: const StadiumBorder(),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String name;
  final String subtitle;
  const _ContactCard({required this.name, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withOpacity(.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 18, backgroundColor: cs.primary.withOpacity(.2), child: const Icon(Icons.person)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text(subtitle, style: tt.bodySmall?.copyWith(color: Colors.black54)),
            ]),
          ),
          Icon(Icons.phone_in_talk_rounded, color: cs.primary),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  const _Bubble({required this.text});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        margin: const EdgeInsets.only(right: 60),
        decoration: BoxDecoration(
          color: cs.primary.withOpacity(.35),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(text),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        color: Colors.white,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Type your response...',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: cs.secondaryContainer),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: const Color(0xFF60B896),
              child: const Icon(Icons.send_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
