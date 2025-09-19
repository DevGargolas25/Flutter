// lib/pages/emergency/emergency_type_page.dart
import 'package:flutter/material.dart';
import 'emergency_success.dart';

class EmergencyTypePage extends StatelessWidget {
  const EmergencyTypePage({super.key});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red.shade400,
        foregroundColor: Colors.white,
        title: Text('Select Emergency Type', style: tt.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          _TypeTile(
            icon: Icons.local_fire_department_rounded,
            iconColor: Colors.deepOrange,
            title: 'Fire Alert',
            subtitle: 'Report fire emergency or smoke detection',
            onTap: () => _goSuccess(context, 'The fire emergency has been reported to the corresponding personnel.'),
          ),
          const SizedBox(height: 12),
          _TypeTile(
            icon: Icons.public_rounded,
            iconColor: Colors.teal,
            title: 'Earthquake Alert',
            subtitle: 'Report seismic activity or structural damage',
            onTap: () => _goSuccess(context, 'The earthquake emergency has been reported to the corresponding personnel.'),
          ),
          const SizedBox(height: 12),
          _TypeTile(
            icon: Icons.medical_services_rounded,
            iconColor: Colors.pinkAccent,
            title: 'Medical Alert',
            subtitle: 'Report medical emergency or injury',
            onTap: () => _goSuccess(context, 'The medical emergency has been reported to the corresponding personnel.'),
          ),
          const SizedBox(height: 16),
          const _InfoPill(text: 'Emergency personnel will be notified immediately upon selection.'),
        ],
      ),
    );
  }

  void _goSuccess(BuildContext ctx, String body) {
    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => EmergencySuccessPage(message: body)),
    );
  }
}

class _TypeTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _TypeTile({required this.icon, required this.iconColor, required this.title, required this.subtitle, required this.onTap});
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
            CircleAvatar(backgroundColor: cs.primary.withOpacity(.15), child: Icon(icon, color: iconColor)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, style: tt.bodyMedium),
              ]),
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
