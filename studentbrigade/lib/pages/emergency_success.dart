// lib/pages/emergency/emergency_success_page.dart
import 'package:flutter/material.dart';
import 'emergency_chat.dart';

class EmergencySuccessPage extends StatelessWidget {
  final String message;
  const EmergencySuccessPage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF60B896),
        foregroundColor: Colors.white,
        title: Text('Alert Sent Successfully', style: tt.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _InfoPill(text: message),
            const Spacer(),
            FilledButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const EmergencyChatPage()),
                      (route) => route.settings.name == '/', // o simplemente (_) => false si quieres cerrar todas
                );
              },
              child: const Text('Open Chat'),
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
