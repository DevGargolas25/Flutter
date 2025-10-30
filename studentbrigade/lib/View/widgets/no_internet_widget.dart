import 'package:flutter/material.dart';

class NoInternetWidget extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? customMessage;

  const NoInternetWidget({super.key, this.onRetry, this.customMessage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline.withOpacity(0.2), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icono de sin internet
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.errorContainer,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.wifi_off_rounded,
              size: 32,
              color: cs.onErrorContainer,
            ),
          ),

          const SizedBox(height: 16),

          // Título
          Text(
            'Sin conexión a internet',
            style: tt.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          // Mensaje
          Text(
            customMessage ??
                'No tienes conexión a internet. Solo se muestran los videos guardados localmente. Ve a un lugar con mejor conexión para ver más contenido.',
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),

          if (onRetry != null) ...[
            const SizedBox(height: 16),

            // Botón de reintentar
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget que se muestra al final de la lista cuando no hay internet
class OfflineEndMessageWidget extends StatelessWidget {
  final VoidCallback? onRetry;

  const OfflineEndMessageWidget({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outline.withOpacity(0.1), width: 1),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded, size: 24, color: cs.onSurfaceVariant),

          const SizedBox(height: 8),

          Text(
            'Sin conexión a internet',
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'Estos son todos los videos disponibles sin conexión. Ve a un lugar con mejor conexión a internet para ver más contenido.',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),

          if (onRetry != null) ...[
            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.wifi_find_rounded, size: 18),
              label: const Text('Verificar conexión'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: cs.outline),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
