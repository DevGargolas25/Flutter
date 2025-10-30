// lib/services/auth_service.dart
import 'dart:convert';
import 'package:auth0_flutter/auth0_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Servicio de autenticación con Auth0 y soporte “offline ligero”.
/// - Primer login/registro SIEMPRE requiere Internet.
/// - Si ya hubo login/restore exitoso alguna vez, se marca un flag persistente
///   (_hasLoggedBeforeKey). Con ese flag la app puede entrar offline (sin tokens).
/// - Solo se persiste el EMAIL (para UX y bootstrap offline).
class AuthService {
  AuthService._();
  static final instance = AuthService._();

  /// Reemplaza con tus valores reales:
  final auth0 = Auth0(
    'dev-wahfof5ie3r5xpns.us.auth0.com',   // domain
    'Rx8m06ZqFz6whAddBBtzAwAyTtQJoS3p',    // clientId
  );

  Credentials? _creds;
  Credentials? get credentials => _creds;

  CredentialsManager get _manager => auth0.credentialsManager;

  // Claves en SharedPreferences
  static const _hasLoggedBeforeKey = 'sb_has_logged_before';
  static const _lastEmailKey       = 'sb_last_email';

  /// Hook opcional para calentar caché/estado con el email autenticado.
  void Function(String email)? afterAuthEmail;

  /// --------- API principal ---------

  /// Intenta restaurar credenciales (si hay refresh token).
  /// Si sale bien, marca flag offline y guarda email.
  Future<bool> restore() async {
    try {
      final c = await _manager.credentials();
      _creds = c;
      await _markHasLoggedBefore();
      final email = c.email;
      if (email != null && email.isNotEmpty) {
        await _storeLastEmail(email);
        afterAuthEmail?.call(email); // hook para calentar caché/estado
      }
      return true;
    } catch (_) {
      _creds = null;
      return false;
    }
  }

  /// Login con Auth0 (requiere internet).
  Future<Credentials?> login() async {
    final c = await auth0
        .webAuthentication(scheme: 'com.example.studentbrigade') // ajusta tu scheme
        .login(
      useHTTPS: true,
      // audience: 'https://tu-api/', // si usas API propia
      scopes: const {'openid', 'profile', 'email', 'offline_access'},
    );

    await _manager.storeCredentials(c);
    _creds = c;

    await _markHasLoggedBefore();

    final email = c.email;
    if (email != null && email.isNotEmpty) {
      await _storeLastEmail(email);
      afterAuthEmail?.call(email); // hook
    }
    return c;
  }

  /// Signup (misma UI que login, con hints).
  Future<Credentials?> signup({String? email}) async {
    final c = await auth0
        .webAuthentication(scheme: 'com.example.studentbrigade')
        .login(
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

    final effectiveEmail = c.email ?? email;
    if (effectiveEmail != null && effectiveEmail.isNotEmpty) {
      await _storeLastEmail(effectiveEmail);
      afterAuthEmail?.call(effectiveEmail); // hook
    }
    return c;
  }

  /// Logout. Limpia estado local SIEMPRE. Intenta logout remoto solo si hay Internet.
  Future<void> logout({bool deep = true}) async {
    // 1) Limpieza local (offline-safe)
    await _manager.clearCredentials();
    _creds = null;

    if (deep) {
      final sp = await SharedPreferences.getInstance();
      await sp.remove(_hasLoggedBeforeKey); // desactiva offline-ligero
      await sp.remove(_lastEmailKey);       // limpia último email
    }

    // 2) Logout remoto (best-effort)
    try {
      final conn = await Connectivity().checkConnectivity();
      final hasNet = conn is List<ConnectivityResult>
          ? conn.any((r) => r != ConnectivityResult.none)
          : (conn as ConnectivityResult) != ConnectivityResult.none;

      if (hasNet) {
        await auth0
            .webAuthentication(scheme: 'com.example.studentbrigade')
            .logout(useHTTPS: true)
            .timeout(const Duration(seconds: 5));
      } else {
        // sin internet → omite logout web
        // (ya hiciste logout local)
      }
    } catch (e) {
      // ignora: logout local ya aplicado
      // debugPrint('Auth0 web logout falló: $e');
    }
  }

  /// Intenta devolver credenciales válidas (refresca si aplica).
  /// Si falla, retorna lo último que haya en memoria (puede ser null).
  Future<Credentials?> getValidCredentials() async {
    try {
      final c = await _manager.credentials();
      _creds = c;
      return c;
    } catch (_) {
      return _creds;
    }
  }

  /// Access token o null si no disponible.
  Future<String?> getAccessTokenOrNull() async {
    final c = await getValidCredentials();
    return c?.accessToken;
  }

  /// --------- Offline ligero & email persistido ---------

  Future<void> _markHasLoggedBefore() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_hasLoggedBeforeKey, true);
  }

  /// Versión estática para consultarlo desde cualquier parte.
  static Future<bool> hasLoggedBefore() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_hasLoggedBeforeKey) ?? false;
  }

  Future<void> _storeLastEmail(String? email) async {
    if (email == null || email.isEmpty) return;
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_lastEmailKey, email.trim().toLowerCase());
  }

  /// Versión estática para obtener el último email guardado.
  static Future<String?> getLastEmail() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_lastEmailKey);
  }

  /// Helpers de testing / mantenimiento
  static Future<void> clearHasLoggedBeforeForTests() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_hasLoggedBeforeKey);
  }

  static Future<void> clearLastEmailForTests() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_lastEmailKey);
  }

  /// Roles actuales (desde claim con namespace en el ID Token).
  List<String> get currentUserRoles => _creds?.roles ?? const [];

  /// Email actual (desde el ID Token; requiere scope "email").
  String? get currentUserEmail => _creds?.email;
}

/// =====================
/// Extensiones de Claims
/// =====================
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
  /// Email estándar del ID Token.
  String? get email => idTokenPayload['email'] as String?;
}

extension CredentialsClaims on Credentials {
  /// Decodifica el payload del ID Token.
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

  String? claimString(String key) => idTokenPayload[key] as String?;

  T? claim<T>(String key) {
    final v = idTokenPayload[key];
    if (v is T) return v;
    return null;
  }
}

