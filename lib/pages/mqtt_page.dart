import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
// MQTT测试服务
// 47.119.17.61 端口1883
// 账号test
// 密码 lucas123
class MqttPage extends StatefulWidget {
  const MqttPage({super.key});

  @override
  State<MqttPage> createState() => _MqttPageState();
}

class _MqttPageState extends State<MqttPage> {
  final TextEditingController _brokerController = TextEditingController(text: '47.119.17.61');
  final TextEditingController _clientIdController = TextEditingController(text: 'client_001');
  final TextEditingController _topicController = TextEditingController(text: 'test/topic');
  final TextEditingController _msgController = TextEditingController();

  late MqttServerClient _client;
  bool _connected = false;
  List<String> _messages = [];
  int _selectedIndex = 0; // 当前选中的底部导航项

  @override
  void dispose() {
    _brokerController.dispose();
    _clientIdController.dispose();
    _topicController.dispose();
    _msgController.dispose();
    if (_connected) _client.disconnect();
    super.dispose();
  }

  Future<void> _connect() async {
    _client = MqttServerClient(_brokerController.text, _clientIdController.text);
    _client.port = 1883;
    _client.keepAlivePeriod = 20;
    _client.onDisconnected = _onDisconnected;
    _client.logging(on: false);
    _client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(_clientIdController.text)
        .authenticateAs('test', 'lucas123')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);
    try {
      await _client.connect();
      if (_client.connectionStatus?.state == MqttConnectionState.connected) {
        setState(() => _connected = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('MQTT 连接成功！'), backgroundColor: Colors.green),
        );
      } else {
        setState(() => _connected = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('连接失败: ${_client.connectionStatus?.returnCode}')),
        );
      }
    } catch (e) {
      setState(() => _connected = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('连接失败: $e')));
    }
  }
  void _disconnect() {
    if (_connected) {
      _client.disconnect();
      setState(() => _connected = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已断开MQTT连接'), backgroundColor: Colors.orange),
      );
    }
    }

    void _onDisconnected() {
    setState(() => _connected = false);
  }

  void _subscribe() {
    if (!_connected) return;
    _client.subscribe(_topicController.text, MqttQos.atLeastOnce);
    _client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      setState(() {
        _messages.insert(0, '[${c[0].topic}] $pt');
      });
    });
  }

  void _publish() {
    if (!_connected) return;
    final builder = MqttClientPayloadBuilder();
    builder.addString(_msgController.text);
    _client.publishMessage(_topicController.text, MqttQos.atLeastOnce, builder.payload!);
    setState(() {
      _messages.insert(0, '[发送] ${_msgController.text}');
      _msgController.clear();
    });
  }

  // 构建连接设置界面
  Widget _buildConnectionSettings() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 连接状态指示器
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: _connected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _connected ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _connected ? Colors.green : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _connected ? '已连接' : '未连接',
                    style: TextStyle(
                      color: _connected ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            TextField(
              controller: _brokerController,
              decoration: const InputDecoration(
                labelText: 'Broker地址',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.dns),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _clientIdController,
              decoration: const InputDecoration(
                labelText: 'Client ID',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.perm_identity),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _connected ? null : _connect,
                    icon: const Icon(Icons.link),
                    label: const Text('连接服务器'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _connected ? null : _disconnect,
                    icon: const Icon(Icons.link),
                    label: const Text('取消连接'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            )

          ],
        ),
      ),
    );
  }

  // 构建订阅设置界面
  Widget _buildSubscriptionSettings() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: 'Topic',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.topic),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _connected ? _subscribe : null,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('订阅主题'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建发布设置界面
  Widget _buildPublishSettings() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: 'Topic',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.topic),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _msgController,
              decoration: const InputDecoration(
                labelText: '消息内容',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.message),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _connected ? _publish : null,
                icon: const Icon(Icons.send),
                label: const Text('发送消息'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建消息记录区域
  Widget _buildMessageList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '消息记录',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () {
                  setState(() {
                    _messages = [];
                  });
                },
                tooltip: '清空记录',
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('暂无消息记录'))
                : ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isReceived = message.startsWith('[test/topic]');
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isReceived
                        ? Colors.blue.withOpacity(0.1)
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isReceived
                          ? Colors.blue.withOpacity(0.3)
                          : Colors.green.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isReceived ? Icons.download : Icons.upload,
                        size: 16,
                        color: isReceived ? Colors.blue : Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          message,
                          style: TextStyle(
                            color: isReceived ? Colors.blue.shade800 : Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MQTT 消息测试'),
        elevation: 0,
        actions: [
          // 添加连接状态指示器到AppBar
          if (_connected)
            Container(
              margin: const EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('已连接', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildConnectionSettings(),
          _buildSubscriptionSettings(),
          _buildPublishSettings(),
          Scaffold(
            body: _buildMessageList(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_ethernet),
            label: '连接',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.subscriptions),
            label: '订阅',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.send),
            label: '发送',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: '消息',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 3 ? FloatingActionButton(
        onPressed: () {
          setState(() {
            _messages = [];
          });
        },
        tooltip: '清空消息记录',
        child: const Icon(Icons.delete_sweep),
      ) : null,
    );
  }
}