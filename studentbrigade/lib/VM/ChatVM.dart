import '../Models/chatModel.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ChatVM extends ChangeNotifier {
  final List<ChatMessage> _chat = [];
  bool _isTyping = false;
  String _baseUrl;

  ChatVM({required String baseUrl}) : _baseUrl = baseUrl.trim() {
    _chat.add(ChatMessage(
      id: 'system_init',
      sender: Sender.system,
      text: 'Eres un asistente útil para una brigada estudiantil de emergencias.',
      time: DateTime.now(),
    ));
  }

  List<ChatMessage> get messages => List.unmodifiable(_chat);
  bool get isTyping => _isTyping;

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
      await _sendToHuggingFace();
    } catch (e) {
      debugPrint('ChatVM Error: $e');
      _addErrorMessage('Sorry, I encountered an error. Please try again.');
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }

    Future<void> _sendToHuggingFace() async {
    try {
      // Usar un modelo más confiable y gratuito
      const apiUrl = 'https://api-inference.huggingface.co/models/microsoft/DialoGPT-medium';
      
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'inputs': _chat.last.text,
          'parameters': {
            'max_new_tokens': 50,
            'temperature': 0.8,
            'return_full_text': false,  // Solo devolver texto nuevo
          }
        }),
      );

      print('🌐 HuggingFace Response Status: ${response.statusCode}');
      print('📝 HuggingFace Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(response.body);
        String botReply = '';
        
        // Manejar diferentes formatos de respuesta
        if (data is List && data.isNotEmpty) {
          if (data[0]['generated_text'] != null) {
            String fullText = data[0]['generated_text'];
            // Extraer solo la parte nueva (después del input)
            botReply = fullText.replaceFirst(_chat.last.text, '').trim();
          }
        } else if (data is Map && data['generated_text'] != null) {
          botReply = data['generated_text'];
        }
        
        // Si no hay respuesta válida o está vacía, usar fallback
        if (botReply.isEmpty || botReply == _chat.last.text) {
          botReply = _getSmartFallbackResponse(_chat.last.text);
        }
        
        _chat.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: Sender.assistant,
          text: botReply,
          time: DateTime.now(),
        ));
      } else if (response.statusCode == 503) {
        // Modelo loading - usar fallback
        print('⏳ Model is loading, using fallback response');
        final fallbackReply = _getSmartFallbackResponse(_chat.last.text);
        _chat.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          sender: Sender.assistant,
          text: fallbackReply,
          time: DateTime.now(),
        ));
      } else {
        throw Exception('Hugging Face API error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ HuggingFace Error: $e');
      // En caso de error, usar respuesta fallback
      final fallbackReply = _getSmartFallbackResponse(_chat.last.text);
      _chat.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sender: Sender.assistant,
        text: fallbackReply,
        time: DateTime.now(),
      ));
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

  void _addErrorMessage(String error) {
    _chat.add(ChatMessage(
      id: 'error_${DateTime.now().millisecondsSinceEpoch}',
      sender: Sender.assistant,
      text: '❌ $error',
      time: DateTime.now(),
    ));
  }

  void clearChat() {
    _chat.clear();
    _chat.add(ChatMessage(
      id: 'system_init',
      sender: Sender.system,
      text: 'Eres un asistente útil para una brigada estudiantil de emergencias.',
      time: DateTime.now(),
    ));
    notifyListeners();
  }
}