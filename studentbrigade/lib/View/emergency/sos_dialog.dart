// lib/widgets/sos_dialog.dart
import 'package:flutter/material.dart';
import '../../app_colors.dart';
import 'emergency_type_dialog.dart';
import 'emergency_chat_screen.dart';

class SosDialog {
  static void show(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header rojo - FIXED CENTERING
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                decoration: BoxDecoration(
                  color: pastelRed,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Close button row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    // Centered content
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 62,
                          height: 62,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.15),
                          ),
                          child: const Center(
                            child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 34),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Emergency Assistance',
                          style: tt.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Choose how you need help',
                          style: tt.bodyMedium?.copyWith(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Cuerpo con opciones
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionTile(
                      leading: Icons.campaign_rounded,
                      title: 'Send Emergency Alert',
                      subtitle: 'Alert campus security and brigade members',
                      onTap: () {
                        // 1) Cierra este diálogo
                        Navigator.of(context).pop();

                        // 2) Abre el selector de tipo de emergencia (Fire/Earthquake/Medical)
                        //    Lo hacemos en el próximo microtask para evitar conflictos con el cierre.
                        Future.microtask(() => EmergencyTypeDialog.show(context));
                      },
                    ),

                    const SizedBox(height: 12),
                    _ActionTile(
                      leading: Icons.support_agent_rounded,
                      title: 'Contact Brigade',
                      subtitle: 'Connect with nearest brigade member',
                      onTap: () {
                        Navigator.of(context).pop(); // cierra el SOS dialog
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const EmergencyChatScreen()),
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: pastelRed.withOpacity(0.25)),
                      ),
                      child: Text(
                        'Your safety is our priority. Help will be dispatched immediately.',
                        style: tt.bodySmall?.copyWith(color: Colors.grey.shade700),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData leading;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade100,
                ),
                child: Icon(leading, color: Colors.grey.shade700),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: tt.bodySmall?.copyWith(color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black26),
            ],
          ),
        ),
      ),
    );
  }
}
