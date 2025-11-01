import '../Models/chatModel.dart';
import 'package:flutter/foundation.dart';
import '../Services/openai_service.dart';
import '../Services/chat_cache_service.dart';
import '../Services/connectivity_service.dart';

class ChatVM extends ChangeNotifier {
  final List<ChatMessage> _chat = [];
  bool _isTyping = false;
  String _systemPrompt;

  // Servicios
  final ChatCacheService _cacheService = ChatCacheService();
  final ConnectivityService _connectivityService = ConnectivityService();

  ChatVM({String? systemPrompt})
    : _systemPrompt =
          (systemPrompt ??
                  'Eres un asistente útil para una brigada estudiantil de emergencias.')
              .trim() {
    _initializeServices();
    _chat.add(
      ChatMessage(
        id: 'system_init',
        sender: Sender.system,
        text: _systemPrompt,
        time: DateTime.now(),
      ),
    );
  }

  /// Inicializa los servicios
  Future<void> _initializeServices() async {
    try {
      await _cacheService.initialize();
      await _connectivityService.initialize();
      print('💬 ChatVM servicios inicializados');
    } catch (e) {
      print('❌ Error inicializando servicios ChatVM: $e');
    }
  }

  List<ChatMessage> get messages => List.unmodifiable(_chat);
  bool get isTyping => _isTyping;
  String get systemPrompt => _systemPrompt;

  /// Reinicia la conversación con un prompt de sistema personalizado
  void resetWithSystemPrompt(String prompt) {
    _systemPrompt = prompt.trim();
    _chat
      ..clear()
      ..add(
        ChatMessage(
          id: 'system_init',
          sender: Sender.system,
          text: _systemPrompt,
          time: DateTime.now(),
        ),
      );
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: Sender.user,
      text: text.trim(),
      time: DateTime.now(),
    );
    _chat.add(userMessage);
    notifyListeners();

    _isTyping = true;
    notifyListeners();

    try {
      String responseText;

      // 1. Verificar cache primero (respuesta instantánea)
      final cachedResponse = _cacheService.getCachedResponse(text);
      if (cachedResponse != null) {
        responseText = cachedResponse;
        print('💾 Usando respuesta cacheada');
      } else if (_connectivityService.hasInternet &&
          OpenAIService.isConfigured) {
        // 2. Con internet: usar OpenAI
        responseText = await OpenAIService.sendChatCompletion(_chat);
        // Guardar respuesta en cache para futuro uso offline
        _cacheService.cacheResponse(text, responseText);
        print('🌐 Respuesta de OpenAI obtenida y cacheada');
      } else {
        // 3. Sin internet o sin API key: fallback inteligente
        responseText = _getSmartFallbackResponse(text);
        print('📱 Usando respuesta offline');
      }

      _chat.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: Sender.assistant,
          text: responseText,
          time: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('ChatVM Error: $e');
      // En caso de cualquier error, usar fallback
      final fallbackResponse = _getSmartFallbackResponse(text);
      _chat.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: Sender.assistant,
          text: fallbackResponse,
          time: DateTime.now(),
        ),
      );
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  // Método fallback con respuestas inteligentes para emergencias
  String _getSmartFallbackResponse(String userText) {
    final text = userText.toLowerCase();

    if (text.contains(
      RegExp(r'\b(emergencia|emergency|ayuda|help|socorro|urgente)\b'),
    )) {
      return 'En caso de emergencia, mantén la calma y sigue estos pasos:\n1. Evalúa la situación de seguridad\n2. Contacta servicios de emergencia (911)\n3. Busca ayuda de la brigada estudiantil\n4. Sigue los protocolos establecidos';
    } else if (text.contains(
      RegExp(r'\b(primeros auxilios|first aid|herida|lesión|accident)\b'),
    )) {
      return 'Para primeros auxilios básicos:\n• Evalúa la escena de seguridad\n• Verifica consciencia de la víctima\n• Para heridas: presión directa con material limpio\n• Mantén a la víctima calmada y estable\n• Busca ayuda médica profesional';
    } else if (text.contains(RegExp(r'\b(incendio|fire|fuego|humo|smoke)\b'))) {
      return 'Procedimiento ante incendios:\n• Activa la alarma\n• Evacúa inmediatamente\n• NO uses elevadores\n• Mantente agachado si hay humo\n• Ve al punto de encuentro\n• Llama a bomberos (119)';
    } else if (text.contains(
      RegExp(r'\b(evacuación|evacuation|terremoto|sismo)\b'),
    )) {
      return 'Plan de evacuación:\n• Mantén la calma\n• Usa escaleras, no elevadores\n• Sigue señales de salida\n• Ve al punto de encuentro designado\n• Espera instrucciones del personal\n• No regreses hasta que sea seguro';
    } else if (text.contains(RegExp(r'\b(gracias|thank|ok|bien|perfecto)\b'))) {
      return '¡De nada! Estoy aquí para ayudarte con procedimientos de emergencia y seguridad. ¿Hay algo más en lo que pueda asistirte?';
    } else {
      return 'Como asistente de la brigada estudiantil, puedo ayudarte con:\n• Procedimientos de emergencia\n• Primeros auxilios básicos\n• Protocolos de evacuación\n• Contacto con brigadistas\n\n¿Qué información necesitas?';
    }
  }

  // _addErrorMessage helper removed (unused)

  void clearChat() {
    resetWithSystemPrompt(_systemPrompt);
  }
}
