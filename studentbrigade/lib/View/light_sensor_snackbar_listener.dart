import 'package:flutter/material.dart';
import '../VM/Orchestrator.dart';

/// Envuelve tu pantalla raíz con este widget para mostrar SnackBars
/// cuando el sensor de luz reporte el tiempo de respuesta (medido en ThemeSensorService).
class LightSensorSnackBarListener extends StatefulWidget {
  final Widget child;
  final Duration throttle;
  final GlobalKey<ScaffoldMessengerState>? scaffoldMessengerKey; // opcional
  final bool showDebugButton; // muestra botones para simular lux

  const LightSensorSnackBarListener({
    super.key,
    required this.child,
    this.throttle = const Duration(milliseconds: 500),
    this.scaffoldMessengerKey,
    this.showDebugButton = false,
  });

  @override
  State<LightSensorSnackBarListener> createState() => _LightSensorSnackBarListenerState();
}

class _LightSensorSnackBarListenerState extends State<LightSensorSnackBarListener> {
  final _orchestrator = Orchestrator();
  DateTime? _lastShownAt;
  String? _lastMsg;

  @override
  void initState() {
    super.initState();
    _orchestrator.addListener(_onOrchestratorUpdate);
  }

  @override
  void dispose() {
    _orchestrator.removeListener(_onOrchestratorUpdate);
    super.dispose();
  }

  void _onOrchestratorUpdate() {
    final msg = _orchestrator.lastLightSensorNotification;
    if (msg == null || !mounted) return;

    final now = DateTime.now();
    // Evita duplicados y bombardeo de SnackBars
    if (_lastMsg == msg && _lastShownAt != null && now.difference(_lastShownAt!) < widget.throttle) {
      return;
    }

    _lastMsg = msg;
    _lastShownAt = now;

    final messenger = widget.scaffoldMessengerKey?.currentState ?? ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      // No hay Messenger disponible en el árbol aún
      debugPrint('LightSensorSnackBarListener: No ScaffoldMessenger disponible para mostrar SnackBar');
      return;
    }

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Widget _buildDebugButtons() {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'light-lux',
            onPressed: () => _orchestrator.themeDebugLux(100), // claro
            tooltip: 'Simular luz alta',
            child: const Icon(Icons.wb_sunny_outlined),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.small(
            heroTag: 'dark-lux',
            onPressed: () => _orchestrator.themeDebugLux(5), // oscuro
            tooltip: 'Simular luz baja',
            child: const Icon(Icons.nightlight_round),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.showDebugButton) return widget.child;
    return Stack(
      children: [
        widget.child,
        _buildDebugButtons(),
      ],
    );
  }
}
