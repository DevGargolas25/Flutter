import 'package:flutter/material.dart';
import 'emergency_type.dart';
import 'emergency_chat.dart';

class EmergencyAssistPage extends StatelessWidget {
  const EmergencyAssistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
        title: Text(
          'Emergency Assistance',
          style: tt.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          _AssistTile(
            icon: Icons.emergency_share_rounded,
            title: 'Send Emergency Alert',
            subtitle: 'Alert campus security and brigade members',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmergencyTypePage()),
              );
            },
          ),
          const SizedBox(height: 12),
          _AssistTile(
            icon: Icons.support_agent_rounded,
            title: 'Contact Brigade',
            subtitle: 'Connect with nearest brigade member',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmergencyChatPage()),
              );
            },
          ),
          const SizedBox(height: 16),
          const _InfoPill(
            text: 'Your safety is our priority. Help will be dispatched immediately.',
          ),
        ],
      ),
    );
  }
}

class _AssistTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _AssistTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.secondaryContainer.withOpacity(.7)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: cs.primary.withOpacity(.15),
              foregroundColor: Colors.black54,
              child: Icon(icon),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: tt.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String text;
  const _InfoPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withOpacity(.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, textAlign: TextAlign.center),
    );
  }
}

