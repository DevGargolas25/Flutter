
/*
class ChatVM extends ChangeNotifier {
  final Adapter _adapter;
  final ChatGPTService _chatGPT;
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  
  ChatViewModel(this._adapter, this._chatGPT);
  
  // Getters
  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  
  // Business Logic
  Future<void> sendMessage(String content) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // 1. Guardar mensaje del usuario en BD
      final userMessage = ChatMessage(
        content: content,
        isUser: true,
        timestamp: DateTime.now(),
      );
      await _adapter.saveChatMessage(userMessage);
      _messages.add(userMessage);
      
      // 2. Obtener respuesta de ChatGPT
      final botResponse = await _chatGPT.getResponse(content);
      final botMessage = ChatMessage(
        content: botResponse,
        isUser: false,
        timestamp: DateTime.now(),
      );
      
      // 3. Guardar respuesta en BD
      await _adapter.saveChatMessage(botMessage);
      _messages.add(botMessage);
      
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> loadChatHistory() async {
    final messages = await _adapter.getChatMessages();
    _messages = messages.map((json) => ChatMessage.fromJson(json)).toList();
    notifyListeners();
  }
}
*/