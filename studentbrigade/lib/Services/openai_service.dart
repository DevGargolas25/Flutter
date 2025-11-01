import 'dart:convert';
import 'package:http/http.dart' as http;
import '../Models/chatModel.dart';

class OpenAIService {
  // 🔑 API Key desde variable de entorno - SEGURO
  static const String _apiKey = String.fromEnvironment(
    'OPENAI_API_KEY',
    defaultValue: 'YOUR_API_KEY_HERE',
  );

  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  static const String _model = 'gpt-3.5-turbo';

  /// Envía mensajes a OpenAI y retorna la respuesta
  static Future<String> sendChatCompletion(List<ChatMessage> messages) async {
    if (_apiKey == 'YOUR_API_KEY_HERE' || _apiKey.isEmpty) {
      throw Exception(
        '⚠️ Configura tu API Key de OpenAI como variable de entorno OPENAI_API_KEY',
      );
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': messages.map((m) => m.toOpenAIMessage()).toList(),
          'max_tokens': 500,
          'temperature': 0.7,
          'presence_penalty': 0.1,
          'frequency_penalty': 0.1,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices']?[0]?['message']?['content']
            ?.toString()
            .trim();

        if (content == null || content.isEmpty) {
          throw Exception('Respuesta vacía de OpenAI');
        }

        return content;
      } else {
        final errorBody = response.body.isNotEmpty
            ? response.body
            : 'Sin detalle';
        throw Exception('OpenAI API Error ${response.statusCode}: $errorBody');
      }
    } catch (e) {
      throw Exception('Error conectando con OpenAI: $e');
    }
  }

  /// Verifica si la API key está configurada
  static bool get isConfigured => _apiKey != 'YOUR_API_KEY_HERE' && _apiKey.isNotEmpty;
}