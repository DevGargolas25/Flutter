// lib/widgets/emergency_type_dialog.dart
import 'package:flutter/material.dart';
import '../../app_colors.dart';
import 'emergency_success_dialog.dart';

class EmergencyTypeDialog {
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
              // ===== Header rojo con icono y textos =====
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                decoration: BoxDecoration(
                  color: pastelRed,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: Column(
                  children: [
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
                    Container(
                      width: 62, height: 62,
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
                      'Select Emergency Type',
                      style: tt.titleLarge?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose the type of emergency to report',
                      style: tt.bodyMedium?.copyWith(color: Colors.white70),
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
                    _TypeTile(
                      icon: Icons.local_fire_department_rounded,
                      iconBg: const Color(0xFFFFE9E3),
                      iconColor: const Color(0xFFFF6A3D),
                      title: 'Fire Alert',
                      subtitle: 'Report fire emergency or smoke detection',
                      onTap: () {
                        Navigator.pop(context);
                        // Aquí podrías llamar a tu backend antes de mostrar el éxito
                        Future.microtask(() =>
                            EmergencySuccessDialog.show(context, EmergencyType.fire));
                      },
                    ),
                    const SizedBox(height: 12),
                    _TypeTile(
                      icon: Icons.public_rounded,
                      iconBg: const Color(0xFFE9F7F0),
                      iconColor: const Color(0xFF2EB580),
                      title: 'Earthquake Alert',
                      subtitle: 'Report seismic activity or structural damage',
                      onTap: () {
                        Navigator.pop(context);
                        Future.microtask(() =>
                            EmergencySuccessDialog.show(context, EmergencyType.earthquake));
                      },
                    ),
                    const SizedBox(height: 12),
                    _TypeTile(
                      icon: Icons.favorite_rounded,
                      iconBg: const Color(0xFFF6ECF5),
                      iconColor: const Color(0xFFE04F8A),
                      title: 'Medical Alert',
                      subtitle: 'Report medical emergency or injury',
                      onTap: () {
                        Navigator.pop(context);
                        Future.microtask(() =>
                            EmergencySuccessDialog.show(context, EmergencyType.medical));
                      },
                    ),

                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF7F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Emergency personnel will be notified immediately upon selection.',
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

class _TypeTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _TypeTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
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
                width: 44, height: 44,
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor),
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

