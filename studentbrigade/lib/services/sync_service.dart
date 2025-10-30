// lib/services/sync_service.dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../VM/Adapter.dart';
import '../services/offline_queue.dart';

class SyncService {
  SyncService._();
  static final SyncService I = SyncService._();

  Adapter? _adapter;               // inyectado tras Firebase.init
  StreamSubscription? _connSub;
  Timer? _periodic;
  bool _running = false;
  bool _isOnline = false;
  bool _flushInFlight = false;

  void start({required Adapter adapter}) {
    if (_running) return;
    _running = true;
    _adapter = adapter;

    // Suscripción a cambios de conectividad (enum o lista)
    _connSub = Connectivity().onConnectivityChanged.listen((dynamic status) {
      debugPrint('SyncService.onConnectivityChanged -> status=$status type=${status.runtimeType}');

      final results = status is List<ConnectivityResult>
          ? status
          : <ConnectivityResult>[status as ConnectivityResult];

      final online = results.any((r) => r != ConnectivityResult.none);

      if (online && !_isOnline) {
        _isOnline = true;
        debugPrint('SyncService: reconectado → intento de flush');
        _flushSafe(); // sin await para no bloquear el stream
      } else {
        _isOnline = online;
      }
    });

    // Chequeo inicial (por si el primer evento tarda)
    Connectivity().checkConnectivity().then((initial) {
      final results = initial is List<ConnectivityResult>
          ? initial
          : <ConnectivityResult>[initial as ConnectivityResult];
      _isOnline = results.any((r) => r != ConnectivityResult.none);
      debugPrint('SyncService: start (online? $_isOnline)');
      if (_isOnline) _flushSafe();
    });

    // Reintento periódico (por si algún flush falló)
    _periodic = Timer.periodic(const Duration(minutes: 2), (_) {
      if (_isOnline) _flushSafe();
    });
  }

  Future<void> kick() async {
    if (_isOnline) await _flushSafe();
  }

  Future<void> _flushSafe() async {
    if (_flushInFlight) return;          // evita solapamiento
    if (_adapter == null) return;

    _flushInFlight = true;
    try {
      final applied = await OfflineQueue.flush(_adapter!);
      if (applied > 0) {
        debugPrint('SyncService: flush aplicó $applied mutaciones');
      } else {
        debugPrint('SyncService: no había mutaciones pendientes');
      }
    } catch (e, st) {
      debugPrint('SyncService: flush falló: $e\n$st');
    } finally {
      _flushInFlight = false;
    }
  }

  void dispose() {
    _connSub?.cancel();
    _periodic?.cancel();
    _running = false;
  }
}
