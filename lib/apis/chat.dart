import 'package:heart_days/common/decode.dart';
import 'package:heart_days/http/http_manager.dart';
import 'package:heart_days/http/model/api_response.dart';

class ChatSession {
  final String sessionId;
  final String type; // 'single' or 'group'
  final String name;
  final String? avatar;
  final String? userId; // 添加 userId 属性
  final LastMessage? lastMessage;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;

  ChatSession({
    required this.sessionId,
    required this.type,
    required this.name,
    this.avatar,
    this.userId, // 添加 userId 参数
    this.lastMessage,
    required this.unreadCount,
    required this.isPinned,
    required this.isMuted,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      sessionId: json['sessionId'] as String,
      type: (json['type'] as String?) ?? 'single',
      // 默认值或抛出错误
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      userId: json['userId'] as String?, // 添加 userId 解析
      lastMessage:
          json['lastMessage'] != null
              ? LastMessage.fromJson(json['lastMessage'])
              : null,
      unreadCount: json['unreadCount'] as int,
      isPinned: json['isPinned'] as bool,
      isMuted: json['isMuted'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'type': type,
      'name': name,
      'avatar': avatar,
      'userId': userId, // 添加 userId 到 JSON
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'isPinned': isPinned,
      'isMuted': isMuted,
    };
  }
}

class LastMessage {
  final String content;
  final String type;
  final String createdAt;
  final String senderId;
  final String status;

  LastMessage({
    required this.content,
    required this.type,
    required this.createdAt,
    required this.senderId,
    required this.status,
  });

  factory LastMessage.fromJson(Map<String, dynamic> json) {
    return LastMessage(
      content: json['content'] as String,
      type: json['type'] as String,
      createdAt: json['createdAt'] as String,
      senderId: json['senderId'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
      'type': type,
      'createdAt': createdAt,
      'senderId': senderId,
      'status': status,
    };
  }
}


class GroupMember {
  final String userId;
  final String nickname;
  final String? avatar;
  final String joinedAt;

  GroupMember({
    required this.userId,
    required this.nickname,
    this.avatar,
    required this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['userId'] as String,
      nickname: json['nickname'] as String,
      avatar: json['avatar'] as String?,
      joinedAt: json['joinedAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'nickname': nickname,
      'avatar': avatar,
      'joinedAt': joinedAt,
    };
  }
}

class ReadMember {
  final String userId;
  final String nickname;
  final String? avatar;
  final String readAt;

  ReadMember({
    required this.userId,
    required this.nickname,
    this.avatar,
    required this.readAt,
  });

  factory ReadMember.fromJson(Map<String, dynamic> json) {
    return ReadMember(
      userId: json['userId'] as String,
      nickname: json['nickname'] as String,
      avatar: json['avatar'] as String?,
      readAt: json['readAt'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'nickname': nickname,
      'avatar': avatar,
      'readAt': readAt,
    };
  }
}

class ChatSessionResponse {
  final String id;
  final String type;
  final String? name; // 根据响应，name 可能为 null
  final String createdAt;
  final String updatedAt;

  ChatSessionResponse({
    required this.id,
    required this.type,
    this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatSessionResponse.fromJson(Map<String, dynamic> json) {
    return ChatSessionResponse(
      id: json['id'],
      type: json['type'],
      name: json['name'] ?? '',
      // 可为 null，所以类型为 dynamic
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}


class ChatMessage {
  final String id;
  final String sessionId;
  final String senderId;
  final String? receiverId;
  final String content;
  final String type;
  final String createdAt;
  final String status;
  final bool? isRead; // 修改为可空 bool

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.senderId,
    this.receiverId,
    required this.content,
    required this.type,
    required this.createdAt,
    required this.status,
    this.isRead, // 修改为可空
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      sessionId: json['sessionId'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      content: json['content'],
      type: json['type'],
      createdAt: json['createdAt'],
      status: json['status'],
      isRead: json['isRead'] as bool?, // 显式转换为 bool?
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['sessionId'] = sessionId;
    data['senderId'] = senderId;
    data['receiverId'] = receiverId;
    data['content'] = content;
    data['type'] = type;
    data['createdAt'] = createdAt;
    data['status'] = status;
    data['isRead'] = isRead; // 保持可空
    return data;
  }
}



/// 创建会话
Future<ApiResponse<ChatSessionResponse>> createChatSession(
  Map<String, dynamic> data,
) async {
  return await HttpManager.post<ChatSessionResponse>(
    "/chat/session",
    data: data,
    fromJson: (json) => ChatSessionResponse.fromJson(json),
  );
}

/// 获取会话列表
Future<ApiResponse<PaginatedData<ChatSession>>> listChatSession(
  Map<String, dynamic> data,
) async {
  return await HttpManager.get<PaginatedData<ChatSession>>(
    "/chat/session-list",
    queryParameters: data,
    fromJson: (json) {
      print('🔍 解析 PaginatedData: $json');
      return PaginatedData<ChatSession>.fromJson(
        json,
        (e) => ChatSession.fromJson(e),
      );
    },
  );
}

/// 获取聊天记录
Future<ApiResponse<PaginatedData<ChatMessage>>> getChatHistoryApi(
  Map<String, dynamic> data,
) async {
  final String sessionId = data['id'];
  return await HttpManager.get<PaginatedData<ChatMessage>>(
    "/chat/session/$sessionId/messages", // 路径格式对应后端
    queryParameters: {
      'limit': data['limit'] ?? 10,
      'offset': data['offset'] ?? 0,
    },
    fromJson: (json) {
      print('🔍 解析 ChatMessage: $json');
      return PaginatedData<ChatMessage>.fromJson(
        json,
        (e) => ChatMessage.fromJson(e),
      );
    },
  );
}

/// 获取会话详情
Future<ApiResponse<ChatSessionResponse>> getChatSessionById(
  String sessionId,
) async {
  return await HttpManager.get<ChatSessionResponse>(
    "/chat/session/$sessionId", // 注意路径要与后端一致
    fromJson: (json) => ChatSessionResponse.fromJson(json),
  );
}

Future<ApiResponse<ChatSessionResponse>> getChatSessionDetail(
  String sessionId,
) async {
  return await HttpManager.get<ChatSessionResponse>(
    "/chat/session/$sessionId", // 注意路径要与后端一致
    fromJson: (json) => ChatSessionResponse.fromJson(json),
  );
}

/// 标记消息已读
Future<ApiResponse<void>> markMessageReadApi(String messageId) async {
  print('标记消息已读');
  return await HttpManager.post<void>(
    "/chat/message/$messageId/read",
    fromJson: (_) => null,

  );
}
