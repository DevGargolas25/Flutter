// ignore: file_names
enum Sender { assistant, user, system }

class ChatMessage {
  final String id;
  final Sender sender;
  final String text;
  final DateTime time;

  ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.time,
  });
  Map<String, dynamic> toOpenAIMessage() {
    final role = switch (sender) {
      Sender.user => "user",
      Sender.assistant => "assistant",
      Sender.system => "system",
    };
    return {"role": role, "content": text};
  }
}
