import '../Models/chatModel.dart'; // ChatMessage, Sender
// chat_vm.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ChatVM extends ChangeNotifier {
  final List<ChatMessage> _chat = [];
  bool _isTyping = false;
  String _baseUrl;

  ChatVM({required String baseUrl}) : _baseUrl = baseUrl.trim() {
    _chat.add(
      ChatMessage(
        id: 'hello',
        sender: Sender.assistant,
        text: "Hello! I'm your Brigade Assistant. How can I help you?",
        time: DateTime.now(),
      ),
    );
  }

  List<ChatMessage> get messages => List.unmodifiable(_chat);
  bool get isTyping => _isTyping;

  set baseUrl(String url) {
    _baseUrl = url.trim();
    notifyListeners();
  }

  Uri _endpoint(String path) {
    final cleanBase = _baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$cleanBase$cleanPath');
  }

  Future<void> sendUserMessage(String text) async {
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: Sender.user,
      text: text,
      time: DateTime.now(),
    );
    _chat.add(userMsg);
    notifyListeners();

    _isTyping = true;
    notifyListeners();

    try {
      final history = _chat.map((m) => m.toOpenAIMessage()).toList();

      final url = _endpoint('/chat');
      debugPrint('POST -> $url'); // <-- verás exactamente qué URL pega

      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"messages": history}),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final replyText = (data['text'] as String?) ?? "(sin respuesta)";
        _chat.add(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            sender: Sender.assistant,
            text: replyText,
            time: DateTime.now(),
          ),
        );
      } else {
        _chat.add(
          ChatMessage(
            id: 'err',
            sender: Sender.assistant,
            text: "Ups, hubo un error ${resp.statusCode}.",
            time: DateTime.now(),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('ChatVM error: $e\n$st'); // <-- stack para depurar
      _chat.add(
        ChatMessage(
          id: 'exc',
          sender: Sender.assistant,
          text: "Error de conexión: $e",
          time: DateTime.now(),
        ),
      );
    } finally {
      _isTyping = false;
      notifyListeners();
    }
  }
}
