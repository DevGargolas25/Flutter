// lib/widgets/emergency_type_dialog.dart
import 'package:flutter/material.dart';
import 'emergency_success_dialog.dart';
import 'package:studentbrigade/VM/Orchestrator.dart';
import 'package:studentbrigade/Models/emergencyMod.dart' as EmerModel;

class EmergencyTypeDialog {
  static void show(BuildContext context) {
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
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                decoration: BoxDecoration(
                  color: cs.error,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Column(
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
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.onError.withAlpha((0.15 * 255).round()),
                      ),
                      child: Center(
                        child: Icon(Icons.warning_amber_rounded, color: cs.onError, size: 34),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select Emergency Type',
                      style: tt.titleLarge?.copyWith(
                        color: cs.onError,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose the type of emergency to report',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onError.withAlpha((0.85 * 255).round()),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // ===== Opciones =====
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // FIRE
                    _TypeTile(
                      icon: Icons.local_fire_department_rounded,
                      containerColor: cs.errorContainer,
                      iconColor: cs.error,
                      title: 'Fire Alert',
                      subtitle: 'Report fire emergency or smoke detection',
                      onTap: () => _onSelect(
                        context: context,
                        persistType: EmerModel.EmergencyType.Hazard, // ajusta si tienes EmergencyType.Fire
                        successDialogType: EmergencyType.fire,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // EARTHQUAKE
                    _TypeTile(
                      icon: Icons.public_rounded,
                      containerColor: cs.secondaryContainer,
                      iconColor: cs.secondary,
                      title: 'Earthquake Alert',
                      subtitle: 'Report seismic activity or structural damage',
                      onTap: () => _onSelect(
                        context: context,
                        persistType: EmerModel.EmergencyType.Hazard, // o un tipo específico si lo tienes
                        successDialogType: EmergencyType.earthquake,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Aquí puedes añadir más tipos (Security, Medical, etc.)
                    // _TypeTile(...)

                    const SizedBox(height: 16),
                    // Nota informativa
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest.withAlpha((0.6 * 255).round()),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Emergency personnel will be notified immediately upon selection.',
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

  /// Helper: cierra el diálogo, llama al brigadista y delega la persistencia en Orchestrator.
  static void _onSelect({
    required BuildContext context,
    required EmerModel.EmergencyType persistType,
    required EmergencyType successDialogType,
  }) {
    Navigator.pop(context);

    final orch = Orchestrator();
    final user = orch.getUserData();

    // 2) Persistir (RTDB offline-friendly). Aquí puede ir routeCalcTime si lo tienes.
    Future.microtask(() async {
      try {
        await orch.persistEmergencyOffline(
          type: persistType,
          // routeCalcTime: someRouteDuration, // pásalo si lo calculas en MapVM
          // assignedBrigadistId: ...          // si ya lo tienes
        );
      } catch (e) {
        // No bloquees la UI por esto; RTDB encolará cuando vuelva internet si setPersistenceEnabled(true)
        debugPrint('persistEmergencyOffline failed: $e');
      }
    });

    // 3) Mostrar confirmación
    Future.microtask(() => EmergencySuccessDialog.show(context, successDialogType));
  }
}

class _TypeTile extends StatelessWidget {
  final IconData icon;
  final Color containerColor;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TypeTile({
    required this.icon,
    required this.containerColor,
    required this.iconColor,
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
        onTap: onTap,
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: containerColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurface.withAlpha((0.7 * 255).round()),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurface.withAlpha((0.35 * 255).round())),
            ],
          ),
        ),
      ),
    );
  }
}
