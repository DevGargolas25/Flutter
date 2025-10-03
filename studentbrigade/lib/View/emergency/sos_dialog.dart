// lib/widgets/sos_dialog.dart
import 'package:flutter/material.dart';
import '../../VM/Orchestrator.dart';
import 'emergency_chat_screen.dart';
import 'emergency_type_dialog.dart';

class SosDialog {
  static void show(BuildContext context, Orchestrator orchestrator) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

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
              // ===== Header SOS =====
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                decoration: BoxDecoration(
                  color: cs.error,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(Icons.close, color: cs.onError),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 62, height: 62,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cs.onError.withOpacity(0.15),
                          ),
                          child: Center(
                            child: Icon(Icons.warning_amber_rounded, color: cs.onError, size: 34),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text('Emergency Assistance',
                          style: tt.titleLarge?.copyWith(color: cs.onError, fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text('Choose how you need help',
                          style: tt.bodyMedium?.copyWith(color: cs.onError.withOpacity(.8)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ===== Body =====
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ActionTile(
                      leading: Icons.campaign_rounded,
                      title: 'Send Emergency Alert',
                      subtitle: 'Alert campus security and brigade members',
                      onTap: () async {
                        Navigator.of(context).pop();
                        Future.microtask(() => EmergencyTypeDialog.show(context));
                      },
                    ),
                    const SizedBox(height: 12),

                    // >>> AQUÍ LLAMA AL PULSAR <<<
                    _ActionTile(
                      leading: Icons.support_agent_rounded,
                      title: 'Contact Brigade',
                      subtitle: 'Call nearest brigade member',
                      onTap: () async {
                        // 1) Prepara navegación post-llamada
                        final nav = Navigator.of(context);
                        bool done = false;

                        void onReturn() {
                          // Orchestrator/EmergencyVM setea lastCallDurationSeconds al volver
                          if (!done && orchestrator.lastCallDurationSeconds != null) {
                            done = true;
                            orchestrator.emergencyVM.removeListener(onReturn);
                            // Abrir chat al regresar del dialer
                            nav.push(MaterialPageRoute(
                              builder: (_) => const EmergencyChatScreen(),
                            ));
                          }
                        }

                        // Suscribirse ANTES de lanzar la llamada
                        orchestrator.emergencyVM.addListener(onReturn);

                        // 2) Cerrar el diálogo
                        nav.pop();

                        // 3) Iniciar la llamada (captura ubicación + abre dialer)
                        try {
                          await orchestrator.callBrigadistWithLocation('+573053343497');
                          // No navegues aquí; la app se va al dialer.
                          // El listener hará el push al volver.
                        } catch (e) {
                          // Si algo falla antes de salir al dialer, limpia listener
                          orchestrator.emergencyVM.removeListener(onReturn);
                          final mounted = nav.mounted;
                          if (mounted) {
                            ScaffoldMessenger.of(nav.context).showSnackBar(
                              SnackBar(content: Text('Error al llamar: $e')),
                            );
                          }
                        }
                      },
                    ),

                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: cs.surfaceVariant.withOpacity(.6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.error.withOpacity(0.25)),
                      ),
                      child: Text(
                        'Your safety is our priority. Help will be dispatched immediately.',
                        style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
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
  final Future<void> Function() onTap; // async

  const _ActionTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => onTap(),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(shape: BoxShape.circle, color: cs.surfaceVariant),
                child: Icon(leading, color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600, color: cs.onSurface)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withOpacity(.7))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurface.withOpacity(.35)),
            ],
          ),
        ),
      ),
    );
  }
}


