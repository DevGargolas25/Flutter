// lib/view/auth_gate.dart
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'auth_service.dart';
import 'welcome_screen.dart';
import 'package:flutter/foundation.dart'; 
import 'package:studentbrigade/VM/Orchestrator.dart';

// Si necesitas navegar a tu Home/NavShell, lo pasas como childWhenAuthed
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
  late final Connectivity _connectivity;

  @override
  void initState() {
    super.initState();
    _connectivity = Connectivity();
    _bootstrap();
  }

  Future<void> _bootstrap() async {

  /*  if (kDebugMode) {
      // En modo debug, saltar autenticación
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loggedIn = true;
      });
      return;
    }*/

    // 1) Detectar red una vez
    final status = await _connectivity.checkConnectivity();
    _offline = (status == ConnectivityResult.none);

    // 2) Intentar restaurar sesión (si hay internet)
    bool restored = false;
    if (!_offline) {
      restored = await AuthService.instance.restore();
      if (restored) {
        final email = AuthService.instance.currentUserEmail;
        if (email != null && email.isNotEmpty) {
          await Orchestrator().loadUserByEmail(email);
        }
      }
    }

    // 3) Si no restauró, pero hubo sesión antes y está offline → permitir Home (modo offline)
    if (!restored && _offline && await AuthService.hasLoggedBefore()) {
      _loggedIn = true;
    } else {
      _loggedIn = restored;
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  Future<void> _doLogin() async {
    setState(() => _loading = true);
    try {
      await AuthService.instance.login(); // guarda y setea _creds internamente
      if (!mounted) return;
      setState(() => _loggedIn = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login falló: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _doSignup() async {
    setState(() => _loading = true);
    try {
      await AuthService.instance.signup(); // guarda y setea _creds internamente
      if (!mounted) return;
      setState(() => _loggedIn = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign up falló: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _loggedIn
        ? widget.childWhenAuthed
        : WelcomeScreen(
      onNavigateToLogin: _doLogin,
      onNavigateToSignUp: _doSignup,
    );
  }
}
