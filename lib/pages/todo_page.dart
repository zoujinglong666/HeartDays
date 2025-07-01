import 'package:flutter/material.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final List<Map<String, dynamic>> _todos = [
    {'title': '完成今日计划', 'done': false, 'priority': 'high'},
    {'title': '阅读30分钟', 'done': false, 'priority': 'medium'},
    {'title': '喝8杯水', 'done': true, 'priority': 'low'},
  ];
  final TextEditingController _controller = TextEditingController();

  static const Color morandiPink = Color(0xFFFBEFF1);
  static const Color morandiBlue = Color(0xFFE6ECF7);
  static const Color morandiGrey = Color(0xFFE0E0E0);

  Color _priorityColor(String p) {
    switch (p) {
      case 'high': return const Color(0xFFFF6B6B);
      case 'medium': return const Color(0xFFFFB74D);
      case 'low': return const Color(0xFF81C784);
      default: return morandiGrey;
    }
  }

  void _addTodo(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _todos.insert(0, {'title': text.trim(), 'done': false, 'priority': 'medium'});
    });
    _controller.clear();
  }

  void _toggleDone(int idx) {
    setState(() {
      _todos[idx]['done'] = !_todos[idx]['done'];
    });
  }

  void _deleteTodo(int idx) {
    setState(() {
      _todos.removeAt(idx);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: morandiPink,
      appBar: AppBar(
        title: const Text('待办事项', style: TextStyle(color: Color(0xFF2C2C2C), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          // 输入框
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: '添加新的待办事项...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onSubmitted: _addTodo,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Material(
                  color: morandiBlue,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _addTodo(_controller.text),
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.add, color: Color(0xFF6C63FF)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 列表
          Expanded(
            child: _todos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox, size: 64, color: morandiGrey),
                        const SizedBox(height: 12),
                        Text('暂无待办事项', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                        const SizedBox(height: 8),
                        const Text('点击下方输入添加你的第一个待办吧~', style: TextStyle(fontSize: 13, color: Color(0xFFBDBDBD))),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: _todos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final todo = _todos[idx];
                      return Dismissible(
                        key: ValueKey(todo['title'] + todo['priority'].toString() + todo['done'].toString()),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, color: Colors.redAccent),
                        ),
                        onDismissed: (_) => _deleteTodo(idx),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _toggleDone(idx),
                              child: Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: todo['done'] ? _priorityColor(todo['priority']).withOpacity(0.15) : Colors.transparent,
                                  border: Border.all(
                                    color: _priorityColor(todo['priority']),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: todo['done']
                                    ? Icon(Icons.check, color: _priorityColor(todo['priority']), size: 20)
                                    : null,
                              ),
                            ),
                            title: Text(
                              todo['title'],
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: todo['done'] ? Colors.grey : Colors.black87,
                                decoration: todo['done'] ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _priorityColor(todo['priority']).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                todo['priority'] == 'high'
                                    ? '高'
                                    : todo['priority'] == 'medium'
                                        ? '中'
                                        : '低',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _priorityColor(todo['priority']),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            onLongPress: () {
                              // 长按切换优先级
                              setState(() {
                                if (todo['priority'] == 'high') {
                                  todo['priority'] = 'medium';
                                } else if (todo['priority'] == 'medium') {
                                  todo['priority'] = 'low';
                                } else {
                                  todo['priority'] = 'high';
                                }
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
} 