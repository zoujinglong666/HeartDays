/// 消息状态枚举
enum MessageSendStatus {
  sending, // 发送中
  success, // 发送成功
  failed   // 发送失败
}

/// 消息模型类
class Message {
  final String localId; // 本地唯一ID
  final String? messageId; // 服务器返回ID
  final String sessionId; // 会话ID
  final bool fromMe; // 是否是自己发送的
  final String text; // 消息内容
  final String createdAt; // 创建时间
  MessageSendStatus sendStatus; // 发送状态
  bool isRead; // 是否已读
  int retryCount; // 重试次数
  String? lastRetryAt; // 最后重试时间

  Message({
    required this.localId,
    this.messageId,
    required this.sessionId,
    required this.fromMe,
    required this.text,
    required this.createdAt,
    this.sendStatus = MessageSendStatus.sending,
    this.isRead = false,
    this.retryCount = 0,
    this.lastRetryAt,
  });

  // 转换为数据库存储格式
  Map<String, dynamic> toDatabaseMap() {
    return {
      'localId': localId,
      'messageId': messageId,
      'sessionId': sessionId,
      'fromMe': fromMe ? 1 : 0,
      'text': text,
      'createdAt': createdAt,
      'sendStatus': sendStatus.index,
      'isRead': isRead ? 1 : 0,
      'retryCount': retryCount,
      'lastRetryAt': lastRetryAt,
    };
  }

  // 从数据库映射创建消息对象
  static Message fromDatabaseMap(Map<String, dynamic> map) {
    return Message(
      localId: map['localId'],
      messageId: map['messageId'],
      sessionId: map['sessionId'],
      fromMe: map['fromMe'] == 1,
      text: map['text'],
      createdAt: map['createdAt'],
      sendStatus: MessageSendStatus.values[map['sendStatus']],
      isRead: map['isRead'] == 1,
      retryCount: map['retryCount'],
      lastRetryAt: map['lastRetryAt'],
    );
  }

  // 复制消息对象并修改部分属性
  Message copyWith({
    String? localId,
    String? messageId,
    String? sessionId,
    bool? fromMe,
    String? text,
    String? createdAt,
    MessageSendStatus? sendStatus,
    bool? isRead,
    int? retryCount,
    String? lastRetryAt,
  }) {
    return Message(
      localId: localId ?? this.localId,
      messageId: messageId ?? this.messageId,
      sessionId: sessionId ?? this.sessionId,
      fromMe: fromMe ?? this.fromMe,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      sendStatus: sendStatus ?? this.sendStatus,
      isRead: isRead ?? this.isRead,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
    );
  }
}