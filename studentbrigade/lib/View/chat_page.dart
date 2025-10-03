// lib/View/chat_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../VM/Orchestrator.dart'; // Orchestrator que expone chatMessages/chatIsTyping/sendChatMessage
import '../Models/chatModel.dart'; // ChatMessage, Sender

class ChatView extends StatefulWidget {
  final Orchestrator orchestrator;
  const ChatView({super.key, required this.orchestrator});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  late final Orchestrator _orch;
  late final VoidCallback _orchListener;

  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _orch = widget.orchestrator;
    // Redibuja cuando cambie el estado del orquestador
    _orchListener = () => setState(() {});
    _orch.addListener(_orchListener);
  }

  @override
  void dispose() {
    _orch.removeListener(_orchListener);
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _orch.sendChatMessage(text);
    _inputCtrl.clear();

    // Desplaza al final cuando se pinte el nuevo mensaje
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final msgs = _orch.chatMessages;
    final isTyping = _orch.chatIsTyping;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F8),
      appBar: _header(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              itemCount: msgs.length + (isTyping ? 1 : 0),
              itemBuilder: (_, i) {
                if (isTyping && i == msgs.length) {
                  return const _TypingRow();
                }
                final m = msgs[i];
                final isUser = m.sender == Sender.user;
                return _ChatRow(message: m, isUser: isUser);
              },
            ),
          ),
          const Divider(height: 1),
          _InputBar(controller: _inputCtrl, onSend: _send),
        ],
      ),
    );
  }

  PreferredSizeWidget _header() {
    return AppBar(
      backgroundColor: const Color(0xFF72C6C1),
      elevation: 0,
      titleSpacing: 0,
      title: Row(
        children: const [
          SizedBox(width: 4),
          CircleAvatar(
            backgroundColor: Colors.white,
            child: Icon(Icons.smart_toy, color: Color(0xFF72C6C1)),
          ),
          SizedBox(width: 10),
          _TitleBlock(),
        ],
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Brigade Assistant',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        Text(
          'Always here to help',
          style: TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}

class _ChatRow extends StatelessWidget {
  final ChatMessage message;
  final bool isUser;
  const _ChatRow({required this.message, required this.isUser});

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isUser ? Colors.white : const Color(0xFF72C6C1);
    final textColor = isUser ? const Color(0xFF1B1F23) : Colors.white;

    final bubble = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: isUser
            ? Text(
                message.text,
                style: TextStyle(fontSize: 14, color: textColor, height: 1.35),
              )
            : MarkdownBody(
                data: message.text,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(fontSize: 14, color: textColor, height: 1.35),
                  h1: TextStyle(color: textColor, fontWeight: FontWeight.w700),
                  h2: TextStyle(color: textColor, fontWeight: FontWeight.w700),
                  strong: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                  ),
                  listBullet: TextStyle(color: textColor),
                ),
              ),
      ),
    );

    final avatar = CircleAvatar(
      radius: 14,
      backgroundColor: isUser ? const Color(0xFFEFF3F4) : Colors.white,
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy,
        size: 16,
        color: isUser ? const Color(0xFF7A8C98) : const Color(0xFF72C6C1),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: isUser
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: isUser
          ? [bubble, const SizedBox(width: 8), avatar]
          : [avatar, const SizedBox(width: 8), bubble],
    );
  }
}

class _TypingRow extends StatelessWidget {
  const _TypingRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 14,
          backgroundColor: Colors.white,
          child: Icon(Icons.smart_toy, size: 16, color: Color(0xFF72C6C1)),
        ),
        const SizedBox(width: 8),
        Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF72C6C1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              _Dot(),
              SizedBox(width: 4),
              _Dot(),
              SizedBox(width: 4),
              _Dot(),
            ],
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatefulWidget {
  const _Dot();

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late final AnimationController c;
  late final Animation<double> a;

  @override
  void initState() {
    super.initState();
    c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    a = Tween(
      begin: .3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: a,
      child: const Icon(Icons.circle, size: 8, color: Colors.white),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _InputBar({required this.controller, required this.onSend});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Type a message…',
                  border: OutlineInputBorder(borderSide: BorderSide.none),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: onSend,
              tooltip: 'Send',
            ),
          ],
        ),
      ),
    );
  }
}
