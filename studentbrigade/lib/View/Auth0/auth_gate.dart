// lib/view/auth_gate.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'auth_service.dart';
import 'welcome_screen.dart';
import 'package:studentbrigade/VM/Orchestrator.dart';
import 'package:studentbrigade/services/offline_queue.dart';
import 'package:studentbrigade/VM/Adapter.dart';

/// Puerta de autenticación con:
/// - Restauración online (Auth0 CredentialsManager).
/// - Opción de "offline ligero" SOLO si el usuario decide continuar.
/// - Visualiza el último email usado para UX.
class AuthGate extends StatefulWidget {
  final Widget childWhenAuthed; // ej: NavShell()

  const AuthGate({super.key, required this.childWhenAuthed});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _loggedIn = false;
  bool _offline = false;
  bool _firstTimeOfflineBlock = false;
  bool _canResumeSession = false; // ← hay sesión previa pero NO entramos solos

  late final Connectivity _connectivity;

  String? _lastEmail; // Solo para mostrar en Welcome

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _bootstrap();
  }

  /// Normaliza el resultado de connectivity_plus (enum o lista) y devuelve true si NO hay red.
  Future<bool> _isOfflineNow() async {
    final status = await _connectivity.checkConnectivity();
    final results = status is List<ConnectivityResult>
        ? status
        : <ConnectivityResult>[status as ConnectivityResult];
    // offline si TODAS las interfaces reportan none (o la lista está vacía)
    return results.isEmpty || results.every((r) => r == ConnectivityResult.none);
  }

  Future<void> _bootstrap() async {
    // 1) Estado de red (robusto)
    _offline = await _isOfflineNow();

    // 2) Intenta restaurar sesión si hay Internet
    bool restored = false;
    if (!_offline) {
      try {
        restored = await AuthService.instance.restore().timeout(const Duration(seconds: 8));
      } catch (e, st) {
        debugPrint('AuthService.restore falló: $e\n$st');
        restored = false;
      }

      // Intentar sincronizar mutaciones encoladas si hay conexión
      try {
        final applied = await OfflineQueue.flush(Adapter());
        if (applied > 0) debugPrint('OfflineQueue: $applied cambios sincronizados');
      } catch (e, st) {
        debugPrint('OfflineQueue.flush falló: $e\n$st');
      }

      // Precargar perfil si restauró (NO marcar _loggedIn todavía)
      if (restored) {
        final email = AuthService.instance.currentUserEmail;
        if (email != null && email.isNotEmpty) {
          _lastEmail = email;
          unawaited(Orchestrator().loadUserByEmail(email));
        }
      }
    }

    // 3) Decisión de entrada
    if (restored) {
      // Hay sesión lista: mostramos Welcome con botón "Continuar"
      _canResumeSession = true;
      _loggedIn = false;
    } else if (_offline) {
      // Offline y NO se restauró → ¿hubo login antes? (offline-ligero)
      bool hadLogin = false;
      try {
        hadLogin = await AuthService.hasLoggedBefore().timeout(const Duration(seconds: 3));
      } catch (e, st) {
        debugPrint('AuthService.hasLoggedBefore fallo: $e\n$st');
        hadLogin = false;
      }

      if (hadLogin) {
        _canResumeSession = true; // NO entrar automático
        try {
          _lastEmail = await AuthService.getLastEmail();
        } catch (e, st) {
          debugPrint('Error cargando lastEmail: $e\n$st');
        }
      } else {
        // Primera vez y sin red → bloquea login/signup
        _firstTimeOfflineBlock = true;
        _loggedIn = false;
      }
    } else {
      // No restauró y hay internet → ver Welcome normal (login/signup)
      _loggedIn = false;
      _canResumeSession = false;
    }

    // 4) Email guardado (UX)
    try {
      _lastEmail = await AuthService.getLastEmail() ?? _lastEmail;
    } catch (e, st) {
      debugPrint('AuthService.getLastEmail fallo: $e\n$st');
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _doLogin() async {
    setState(() => _loading = true);
    try {
      final creds = await AuthService.instance.login(); // guarda tokens internamente
      if (!mounted) return;
      if (creds != null) {
        final email = creds.email;
        if (email != null && email.isNotEmpty) {
          _lastEmail = email;
          // Tras primer login: carga el perfil desde remoto ANTES de entrar
          try {
            await Orchestrator().loadUserByEmail(email);
          } catch (e, st) {
            debugPrint('Carga de perfil tras login falló: $e\n$st');
          }
        }
        setState(() => _loggedIn = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login no completado')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _doSignup() async {
    setState(() => _loading = true);
    try {
      final creds = await AuthService.instance.signup();
      if (!mounted) return;
      if (creds != null) {
        final email = creds.email;
        if (email != null && email.isNotEmpty) {
          _lastEmail = email;
          try {
            await Orchestrator().loadUserByEmail(email);
          } catch (e, st) {
            debugPrint('Carga de perfil tras signup falló: $e\n$st');
          }
        }
        setState(() => _loggedIn = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign up not completed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Continuar sesión (online u offline) sin forzar autenticación nueva.
  Future<void> _continueSession() async {
    setState(() => _loading = true);
    try {
      final email = AuthService.instance.currentUserEmail ?? _lastEmail;
      if (email != null && email.isNotEmpty) {
        try {
          await Orchestrator().loadUserByEmail(email);
        } catch (e, st) {
          debugPrint('Carga de perfil en continue fallo: $e\n$st');
        }
      }
      setState(() {
        _loggedIn = true;        // ahora sí entra a Home
        _canResumeSession = false;
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showNeedInternet() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Internet is required for the first sign-in.')),
    );
  }

  @override
  void dispose() {
    // Sin suscripciones que cancelar
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_loggedIn) {
      return widget.childWhenAuthed;
    }

    final canContinue = _canResumeSession && !_firstTimeOfflineBlock;

    return WelcomeScreen(
      onNavigateToLogin: _firstTimeOfflineBlock ? _showNeedInternet : _doLogin,
      onNavigateToSignUp: _firstTimeOfflineBlock ? _showNeedInternet : _doSignup,
      onContinueSession: canContinue ? _continueSession : null, // ← botón opcional
      disableAuthButtons: _firstTimeOfflineBlock,
      lastEmail: _lastEmail,
    );
  }
}
