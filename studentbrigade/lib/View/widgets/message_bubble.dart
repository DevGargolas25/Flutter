import 'package:flutter/material.dart';
import 'message.dart';

class MessageBubble extends StatelessWidget {
  final Message msg;
  const MessageBubble({super.key, required this.msg});

  @override
  Widget build(BuildContext context) {
    final isMe = !msg.fromBot;
    final bg = isMe
        ? const Color(0xFF5FB38C) // verde usuario
        : const Color(0xFFAED9DA); // turquesa claro bot

    final textColor = isMe ? Colors.white : const Color(0xFF183D3D);
    final align = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: isMe ? const Radius.circular(14) : const Radius.circular(4),
      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(14),
    );

    return Column(
      crossAxisAlignment: align,
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(color: bg, borderRadius: radius),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Text(
            msg.text,
            style: TextStyle(color: textColor, fontSize: 15),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          msg.time,
          style: const TextStyle(color: Colors.black45, fontSize: 11),
        ),
      ],
    );
  }
}
