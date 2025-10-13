import '../Models/chatModel.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ChatVM extends ChangeNotifier {
  final List<ChatMessage> _chat = [];
  bool _isTyping = false;
  String _systemPrompt;

  // Llave para chatbot
  static const String _openAIKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');

  ChatVM({String? systemPrompt})
      : _systemPrompt = (systemPrompt ?? 'Eres un asistente útil para una brigada estudiantil de emergencias.').trim() {
    _chat.add(ChatMessage(
      id: 'system_init',
      sender: Sender.system,
      text: _systemPrompt,
      time: DateTime.now(),
    ));
  }

  List<ChatMessage> get messages => List.unmodifiable(_chat);
  bool get isTyping => _isTyping;
  String get systemPrompt => _systemPrompt;

  /// Reinicia la conversación con un prompt de sistema personalizado
  void resetWithSystemPrompt(String prompt) {
    _systemPrompt = prompt.trim();
    _chat
      ..clear()
      ..add(ChatMessage(
        id: 'system_init',
        sender: Sender.system,
        text: _systemPrompt,
        time: DateTime.now(),
      ));
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
      // 1) Intentar con ChatGPT directo
      await _sendToChatGPT();
    } catch (e) {
      debugPrint('ChatVM Error (ChatGPT): $e');
      // 2) Fallback respuestas básicas si falla
      final reply = _getSmartFallbackResponse(text);
      _chat.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: Sender.assistant,
        text: reply,
        time: DateTime.now(),
      ));
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

  Future<void> _sendToChatGPT() async {
    if (_openAIKey.isEmpty) {
      // Sin clave → lanzar para que active fallback
      throw Exception('OPENAI_API_KEY no configurada (usa --dart-define).');
    }

    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_openAIKey',
      },
      body: jsonEncode({
        'model': 'gpt-3.5-turbo', // puedes usar 'gpt-4o-mini' si tienes acceso
        'messages': _chat.map((m) => m.toOpenAIMessage()).toList(),
        'max_tokens': 500,
        'temperature': 0.7,
        'presence_penalty': 0.1,
        'frequency_penalty': 0.1,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final replyText = data['choices']?[0]?['message']?['content']?.toString().trim();
      if (replyText == null || replyText.isEmpty) {
        // Si vino vacío, usamos fallback
        final fallback = _getSmartFallbackResponse(_chat.last.text);
        _chat.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: Sender.assistant,
          text: fallback,
          time: DateTime.now(),
        ));
        return;
      }

      _chat.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: Sender.assistant,
        text: replyText,
        time: DateTime.now(),
      ));
    } else {
      final body = response.body.isNotEmpty ? response.body : '';
      throw Exception('OpenAI API error ${response.statusCode}: $body');
    }
  }


  // Método fallback con respuestas inteligentes para emergencias
  String _getSmartFallbackResponse(String userText) {
    final text = userText.toLowerCase();
    
    if (text.contains(RegExp(r'\b(emergencia|emergency|ayuda|help|socorro|urgente)\b'))) {
      return 'En caso de emergencia, mantén la calma y sigue estos pasos:\n1. Evalúa la situación de seguridad\n2. Contacta servicios de emergencia (911)\n3. Busca ayuda de la brigada estudiantil\n4. Sigue los protocolos establecidos';
    } else if (text.contains(RegExp(r'\b(primeros auxilios|first aid|herida|lesión|accident)\b'))) {
      return 'Para primeros auxilios básicos:\n• Evalúa la escena de seguridad\n• Verifica consciencia de la víctima\n• Para heridas: presión directa con material limpio\n• Mantén a la víctima calmada y estable\n• Busca ayuda médica profesional';
    } else if (text.contains(RegExp(r'\b(incendio|fire|fuego|humo|smoke)\b'))) {
      return 'Procedimiento ante incendios:\n• Activa la alarma\n• Evacúa inmediatamente\n• NO uses elevadores\n• Mantente agachado si hay humo\n• Ve al punto de encuentro\n• Llama a bomberos (119)';
    } else if (text.contains(RegExp(r'\b(evacuación|evacuation|terremoto|sismo)\b'))) {
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