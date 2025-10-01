// lib/services/auth_service.dart
import 'dart:convert';
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  AuthService._();
  static final instance = AuthService._();

  static const _hasLoggedBeforeKey = 'sb_has_logged_before';

  // ⚠️ Reemplaza por tus valores reales de Auth0
  final auth0 = Auth0(
    'dev-wahfof5ie3r5xpns.us.auth0.com',
    'Rx8m06ZqFz6whAddBBtzAwAyTtQJoS3p',
  );

  Credentials? _creds;
  Credentials? get credentials => _creds;

  CredentialsManager get _manager => auth0.credentialsManager;

  /// Intenta restaurar/renovar credenciales (si hay refresh token).
  Future<bool> restore() async {
    try {
      final c = await _manager.credentials();
      _creds = c;
      await _markHasLoggedBefore();
      return true;
    } catch (_) {
      _creds = null;
      return false;
    }
  }

  Future<Credentials?> login() async {
    final c = await auth0.webAuthentication(
      scheme: 'com.example.studentbrigade',
    ).login(
      useHTTPS: true,
      // Si llamas a tu API, agrega: audience: 'https://tu-api/',
      scopes: const {'openid', 'profile', 'email', 'offline_access'},
    );
    await _manager.storeCredentials(c);
    _creds = c;
    await _markHasLoggedBefore();
    return c;
  }

  Future<Credentials?> signup({String? email}) async {
    final c = await auth0.webAuthentication(
      scheme: 'com.example.studentbrigade',
    ).login(
      useHTTPS: true,
      parameters: {
        'screen_hint': 'signup',
        if (email != null) 'login_hint': email,
      },
      // audience: 'https://tu-api/',
      scopes: const {'openid', 'profile', 'email', 'offline_access'},
    );
    await _manager.storeCredentials(c);
    _creds = c;
    await _markHasLoggedBefore();
    return c;
  }

  Future<void> logout() async {
    await _manager.clearCredentials(); // borra del almacén seguro
    await auth0
        .webAuthentication(scheme: 'com.example.studentbrigade')
        .logout(useHTTPS: true); // iOS/macOS; en Android cierra el SSO del webview
    _creds = null;
  }

  /// Roles actuales (desde el claim con namespace).
  List<String> get currentUserRoles => _creds?.roles ?? const [];

  /// Email actual (desde el ID Token; requiere scope "email").
  String? get currentUserEmail => _creds?.email;

  Future<void> _markHasLoggedBefore() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_hasLoggedBeforeKey, true);
  }

  static Future<bool> hasLoggedBefore() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_hasLoggedBeforeKey) ?? false;
  }
}

/// =====================
/// Extensiones de Claims
/// =====================

/// Asegúrate de agregar en una Auth0 Action (Post-Login):
/// api.idToken.setCustomClaim("https://studentbrigade/roles", event.authorization?.roles || []);
extension CredentialsRoles on Credentials {
  List<String> get roles {
    final r = idTokenPayload['https://studentbrigade/roles'];
    if (r is List) {
      return r.map((e) => e.toString()).toList();
    }
    return const [];
  }
}

extension CredentialsEmail on Credentials {
  /// Lee el email del payload del ID Token (claim estándar "email").
  String? get email => idTokenPayload['email'] as String?;
}

extension CredentialsClaims on Credentials {
  /// Decodifica de forma segura el payload del ID Token a Map.
  Map<String, dynamic> get idTokenPayload {
    if (idToken.isEmpty) return const {};
    final parts = idToken.split('.');
    if (parts.length != 3) return const {};
    try {
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final data = json.decode(payload);
      if (data is Map<String, dynamic>) return data;
      return const {};
    } catch (_) {
      return const {};
    }
  }

  /// Lectura genérica de un claim como String.
  String? claimString(String key) => idTokenPayload[key] as String?;

  /// Lectura genérica de un claim tipado.
  T? claim<T>(String key) {
    final v = idTokenPayload[key];
    if (v is T) return v;
    return null;
  }
}


