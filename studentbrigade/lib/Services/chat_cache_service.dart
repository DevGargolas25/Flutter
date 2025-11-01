import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../cache/lru.dart';

class ChatCacheService {
  // Singleton
  static final ChatCacheService _instance = ChatCacheService._internal();
  factory ChatCacheService() => _instance;
  ChatCacheService._internal();

  // LRU cache para respuestas frecuentes
  final LruCache<String, String> _responseCache = LruCache(50);

  // Archivo para respuestas offline persistentes
  File? _offlineResponsesFile;

  /// Inicializa el servicio de cache
  Future<void> initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _offlineResponsesFile = File(
        '${appDir.path}/chat_offline_responses.json',
      );
      await _loadOfflineResponses();
      print('💬 ChatCacheService inicializado');
    } catch (e) {
      print('❌ Error inicializando ChatCacheService: $e');
    }
  }

  /// Busca respuesta en cache (LRU + archivo offline)
  String? getCachedResponse(String userMessage) {
    final key = _normalizeMessage(userMessage);

    // 1. Buscar en LRU primero
    final lruResponse = _responseCache.get(key);
    if (lruResponse != null) {
      print('💾 Respuesta encontrada en LRU cache');
      return lruResponse;
    }

    // 2. Buscar en respuestas offline predefinidas
    final offlineResponse = _getOfflineResponse(userMessage);
    if (offlineResponse != null) {
      // Guardar en LRU para próxima vez
      _responseCache.put(key, offlineResponse);
      print('📱 Respuesta encontrada en cache offline');
      return offlineResponse;
    }

    return null;
  }

  /// Guarda respuesta en cache
  void cacheResponse(String userMessage, String assistantResponse) {
    final key = _normalizeMessage(userMessage);
    _responseCache.put(key, assistantResponse);
    print('💾 Respuesta guardada en cache');
  }

  /// Normaliza mensaje para usar como key
  String _normalizeMessage(String message) {
    return message.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Carga respuestas offline desde archivo
  Future<void> _loadOfflineResponses() async {
    try {
      if (_offlineResponsesFile?.existsSync() != true) {
        await _createDefaultOfflineResponses();
        return;
      }

      final content = await _offlineResponsesFile!.readAsString();
      final responses = jsonDecode(content) as Map<String, dynamic>;

      // Cargar respuestas en LRU cache
      responses.forEach((key, value) {
        _responseCache.put(key, value.toString());
      });

      print('📱 ${responses.length} respuestas offline cargadas');
    } catch (e) {
      print('❌ Error cargando respuestas offline: $e');
      await _createDefaultOfflineResponses();
    }
  }

  /// Crea respuestas offline por defecto
  Future<void> _createDefaultOfflineResponses() async {
    final defaultResponses = {
      'hola':
          '¡Hola! Soy tu asistente de brigada estudiantil. ¿En qué puedo ayudarte hoy?',
      'emergencia':
          'En caso de emergencia:\n• Mantén la calma\n• Evalúa la situación\n• Contacta al 911\n• Busca a un brigadista\n• Sigue protocolos de seguridad',
      'primeros auxilios':
          'Primeros auxilios básicos:\n• Seguridad primero\n• Evalúa consciencia\n• Controla hemorragias\n• Mantén vía aérea libre\n• Busca ayuda médica',
      'incendio':
          'Protocolo de incendio:\n• Activa alarma\n• Evacúa inmediatamente\n• No uses elevadores\n• Punto de encuentro\n• Llama bomberos (119)',
      'evacuacion':
          'Plan de evacuación:\n• Salidas de emergencia\n• Escaleras solamente\n• Punto de encuentro\n• Lista de verificación\n• Espera instrucciones',
      'ayuda':
          'Puedo ayudarte con:\n• Procedimientos de emergencia\n• Primeros auxilios\n• Protocolos de evacuación\n• Contactos de brigada\n• Información de seguridad',
    };

    try {
      await _offlineResponsesFile!.writeAsString(jsonEncode(defaultResponses));

      // Cargar en cache
      defaultResponses.forEach((key, value) {
        _responseCache.put(key, value);
      });

      print('✅ Respuestas offline por defecto creadas');
    } catch (e) {
      print('❌ Error creando respuestas offline: $e');
    }
  }

  /// Obtiene respuesta offline inteligente
  String? _getOfflineResponse(String userMessage) {
    final text = _normalizeMessage(userMessage);

    // Búsqueda por palabras clave
    final keywords = {
      'hola|hello|hi|buenas': 'hola',
      'emergencia|emergency|urgente|socorro': 'emergencia',
      'primeros auxilios|first aid|herida|lesion': 'primeros auxilios',
      'incendio|fire|fuego|humo': 'incendio',
      'evacuacion|evacuation|terremoto|sismo': 'evacuacion',
      'ayuda|help|asistir|informacion': 'ayuda',
    };

    for (final entry in keywords.entries) {
      if (RegExp(entry.key).hasMatch(text)) {
        return _responseCache.get(entry.value);
      }
    }

    return null;
  }

  /// Limpia todo el cache
  void clearCache() {
    _responseCache.clear();
    print('🗑️ Cache de chat limpiado');
  }

  /// Información del cache
  Map<String, dynamic> getCacheInfo() {
    return {
      'lru_cache_size': _responseCache.length,
      'max_lru_capacity': _responseCache.capacity,
      'offline_file_exists': _offlineResponsesFile?.existsSync() ?? false,
    };
  }
}
