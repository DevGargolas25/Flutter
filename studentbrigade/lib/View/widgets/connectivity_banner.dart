import 'package:flutter/material.dart';
import '../../services/connectivity_service.dart';

/// Widget global que muestra el estado de conectividad de forma dinámica
class ConnectivityBanner extends StatefulWidget {
  final Widget child;

  const ConnectivityBanner({super.key, required this.child});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner>
    with TickerProviderStateMixin {
  final ConnectivityService _connectivity = ConnectivityService();

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _opacityAnimation;

  bool _wasOffline = false;
  bool _showingReconnectedMessage = false;

  @override
  void initState() {
    super.initState();

    // Configurar animaciones
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Escuchar cambios de conectividad
    _connectivity.addListener(_onConnectivityChanged);

    // Estado inicial
    _wasOffline = _connectivity.isOffline;
    if (_wasOffline) {
      _animationController.forward();
    }
  }

  void _onConnectivityChanged() {
    final isCurrentlyOffline = _connectivity.isOffline;

    if (!mounted) return;

    if (_wasOffline && !isCurrentlyOffline) {
      // Se recuperó la conexión
      setState(() {
        _showingReconnectedMessage = true;
      });

      // Mostrar mensaje de reconectado por 3 segundos
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showingReconnectedMessage = false;
          });
          _animationController.reverse();
        }
      });
    } else if (!_wasOffline && isCurrentlyOffline) {
      // Se perdió la conexión
      setState(() {
        _showingReconnectedMessage = false;
      });
      _animationController.forward();
    } else if (!isCurrentlyOffline && !_showingReconnectedMessage) {
      // Tiene conexión y no está mostrando mensaje de reconectado
      _animationController.reverse();
    }

    _wasOffline = isCurrentlyOffline;
  }

  @override
  void dispose() {
    _connectivity.removeListener(_onConnectivityChanged);
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Contenido principal
          widget.child,

          // Banner de conectividad
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              final isOffline = _connectivity.isOffline;
              final showBanner =
                  _animationController.value > 0.0 &&
                  (isOffline || _showingReconnectedMessage);

              if (!showBanner) {
                return const SizedBox.shrink();
              }

              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Transform.translate(
                  offset: Offset(0, _slideAnimation.value * 100),
                  child: Opacity(
                    opacity: _opacityAnimation.value,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.only(
                        top: MediaQuery.of(context).padding.top + 8,
                        bottom: 12,
                        left: 16,
                        right: 16,
                      ),
                      decoration: BoxDecoration(
                        color: _showingReconnectedMessage
                            ? Colors.green.shade600
                            : Colors.orange.shade600,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          children: [
                            Icon(
                              _showingReconnectedMessage
                                  ? Icons.wifi
                                  : Icons.wifi_off,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _showingReconnectedMessage
                                    ? '¡Conexión restaurada! Ya puedes ver todo el contenido.'
                                    : 'Sin conexión a internet. Solo contenido guardado disponible.',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (!_showingReconnectedMessage)
                              GestureDetector(
                                onTap: () async {
                                  await _connectivity.checkConnectivity();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.refresh,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Reintentar',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
