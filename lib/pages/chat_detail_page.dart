import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter/material.dart';
import 'package:heart_days/services/ChatSocketService.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatDetailPage extends StatefulWidget {
  final String name;
  final String avatar;

  const ChatDetailPage({super.key, required this.name, required this.avatar});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final List<Map<String, dynamic>> messages = [
    {'fromMe': false, 'text': '你好呀！'},
    {'fromMe': true, 'text': '你好！'},
    {'fromMe': false, 'text': '今天过得怎么样？'},
    {'fromMe': true, 'text': '很开心，和你聊聊天更开心！'},
  ];
  final TextEditingController _controller = TextEditingController();
  Future<void> _sendMessage() async {
    print('发送消息：${_controller.text}');
    final prefs = await SharedPreferences.getInstance();
    final token= prefs.getString('token');
    ChatSocketService().connect(token!);
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        messages.add({'fromMe': true, 'text': text});
        _controller.clear();
      });
      // 可在此处集成实际消息发送逻辑
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.avatar.isNotEmpty
                  ? NetworkImage(widget.avatar)
                  : null,
              radius: 16,
              child: widget.avatar.isEmpty
                  ? const Icon(Icons.chat_bubble_outline)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(widget.name),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg['fromMe'] as bool;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 14),
                    decoration: BoxDecoration(
                      color: isMe
                          ? Colors.pinkAccent.withOpacity(0.15)
                          : Colors.grey.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg['text'],
                      style: TextStyle(
                        color: isMe ? Colors.pink : Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Divider(height: 1),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: '输入消息...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.pink),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}