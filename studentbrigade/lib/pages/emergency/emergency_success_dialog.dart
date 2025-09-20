import 'package:flutter/material.dart';
import '../../app_colors.dart';

enum EmergencyType { fire, earthquake, medical }

class EmergencySuccessDialog {
  static void show(BuildContext context, EmergencyType type) {
    final tt = Theme.of(context).textTheme;

    // Mensajes por tipo
    final title = 'Alert Sent Successfully';
    final subtitle = 'Emergency personnel have been notified';
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
              // Header verde con icono - MÁS ALTO
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 32), // Más padding vertical
                decoration: BoxDecoration(
                  color: greenShade, // de app_colors.dart
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72, // Icono más grande
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.16),
                      ),
                      child: const Center(
                        child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 40), // Icono más grande
                      ),
                    ),
                    const SizedBox(height: 16), // Más espacio
                    Text(
                      title,
                      style: tt.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20, // Texto más grande
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8), // Más espacio
                    Text(
                      subtitle,
                      style: tt.bodyMedium?.copyWith(
                        color: Colors.white70,
                        fontSize: 16, // Texto más grande
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Mensaje inferior - MÁS ESPACIO
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24), // Más padding
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18), // Más padding interno
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7F1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    body,
                    style: tt.bodyMedium?.copyWith(
                      color: Colors.grey.shade800,
                      fontSize: 15, // Texto más grande
                      height: 1.4, // Más altura de línea
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
