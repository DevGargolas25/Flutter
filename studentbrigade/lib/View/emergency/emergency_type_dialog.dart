// lib/widgets/emergency_type_dialog.dart
import 'package:flutter/material.dart';
import 'emergency_success_dialog.dart';

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
              // ===== Header SOS (usa error/onError) =====
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
                        color: cs.onError.withOpacity(0.15),
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
                      style: tt.bodyMedium?.copyWith(color: cs.onError.withOpacity(.85)),
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
                      onTap: () {
                        Navigator.pop(context);
                        Future.microtask(
                              () => EmergencySuccessDialog.show(context, EmergencyType.fire),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // EARTHQUAKE
                    _TypeTile(
                      icon: Icons.public_rounded,
                      containerColor: cs.secondaryContainer,
                      iconColor: cs.secondary,
                      title: 'Earthquake Alert',
                      subtitle: 'Report seismic activity or structural damage',
                      onTap: () {
                        Navigator.pop(context);
                        Future.microtask(
                              () => EmergencySuccessDialog.show(context, EmergencyType.earthquake),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // MEDICAL
                    _TypeTile(
                      icon: Icons.favorite_rounded,
                      containerColor: cs.tertiaryContainer,
                      iconColor: cs.tertiary,
                      title: 'Medical Alert',
                      subtitle: 'Report medical emergency or injury',
                      onTap: () {
                        Navigator.pop(context);
                        Future.microtask(
                              () => EmergencySuccessDialog.show(context, EmergencyType.medical),
                        );
                      },
                    ),

                    const SizedBox(height: 16),
                    // Nota informativa que respeta tema
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: cs.surfaceVariant.withOpacity(.6),
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
                      style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(.7)),
                    ),
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

