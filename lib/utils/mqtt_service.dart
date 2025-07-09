import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
// MQTT测试服务
// 47.119.17.61 端口1883
// 账号test
// 密码 lucas123
class MqttService {
  final String server;
  final String clientId;
  late MqttServerClient client;

  MqttService({required this.server, required this.clientId}) {
    client = MqttServerClient(server, clientId);
    // 后台mqtt 端口
    client.port = 1883;
    client.keepAlivePeriod = 20;
    client.onDisconnected = onDisconnected;
    client.logging(on: false);
  }

  Future<void> connect() async {
    client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    try {
      await client.connect();
      print('MQTT Connected');
    } catch (e) {
      print('MQTT Connection failed: $e');
      disconnect();
    }
  }

  void subscribe(String topic) {
    client.subscribe(topic, MqttQos.atLeastOnce);
    client.updates?.listen((List<MqttReceivedMessage<MqttMessage>> c) {
      final recMess = c[0].payload as MqttPublishMessage;
      final pt = MqttPublishPayload.bytesToStringAsString(recMess.payload.message);
      print('Received message: $pt from topic: ${c[0].topic}>');
      // 你可以在这里处理消息
    });
  }

  void publish(String topic, String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);
    client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
  }

  void disconnect() {
    client.disconnect();
  }

  void onDisconnected() {
    print('MQTT Disconnected');
  }
}