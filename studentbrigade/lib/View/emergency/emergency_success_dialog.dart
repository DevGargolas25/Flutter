import 'package:flutter/material.dart';

enum EmergencyType { fire, earthquake, medical }

class EmergencySuccessDialog {
  static void show(BuildContext context, EmergencyType type) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    // Mensajes por tipo
    const title = 'Alert Sent Successfully';
    const subtitle = 'Emergency personnel have been notified';
    final body = switch (type) {
      EmergencyType.fire =>
      'The fire emergency has been reported to the corresponding personnel.',
      EmergencyType.earthquake =>
      'The earthquake emergency has been reported to the corresponding personnel.',
      EmergencyType.medical =>
      'The medical emergency has been reported to the corresponding personnel.',
    };

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
              // ===== Header de “éxito”: usa secondary / onSecondary =====
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                decoration: BoxDecoration(
                  color: cs.secondary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: cs.onSecondary.withOpacity(0.16),
                      ),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: cs.onSecondary,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: tt.titleLarge?.copyWith(
                        color: cs.onSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSecondary.withOpacity(.85),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // ===== Mensaje inferior: usa surfaceVariant / onSurfaceVariant =====
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  decoration: BoxDecoration(
                    color: cs.surfaceVariant.withOpacity(.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Text(
                    body,
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 15,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

