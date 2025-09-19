class Message {
  final bool fromBot;
  final String text;
  final String time;

  const Message({
    required this.fromBot,
    required this.text,
    required this.time,
  });
}
