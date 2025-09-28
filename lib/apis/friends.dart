import 'package:heart_days/apis/user.dart';
import 'package:heart_days/http/http_manager.dart';
import 'package:heart_days/http/model/api_response.dart';


class FriendRequestVO {
  final int id;
  final String userId;
  final String friendId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final UserVO fromUser;

  FriendRequestVO({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.fromUser,
  });

  factory FriendRequestVO.fromJson(Map<String, dynamic> json) {
    return FriendRequestVO(
      id: json['id'],
      userId: json['user_id'],
      friendId: json['friend_id'],
      status: json['status'] ?? 'unknown',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      fromUser: UserVO.fromJson(json['fromUser']),
    );
  }
}



Future<ApiResponse<bool>> friendsRequestApi(Map<String, dynamic> data) async {
  return await HttpManager.post<bool>(
    "/friends/request",
    data: data,
  );
}


Future<ApiResponse<List<FriendRequestVO>>> listFriendsRequestApi() async {
  return await HttpManager.get<List<FriendRequestVO>>(
    "/friends/requests/received",
    fromJson: (json) {
      if (json is List) {
        return json.map((item) => FriendRequestVO.fromJson(item)).toList();
      }
      return [];
    },
  );
}


Future<ApiResponse<bool>> friendsRespondStatusApi(Map<String, dynamic> data) async {
  return await HttpManager.post<bool>(
    "/friends/respond",
    data: data,
  );
}
Future<ApiResponse<bool>> settingFriendNickNameApi(Map<String, dynamic> data) async {
  return await HttpManager.post<bool>(
    "/friends/setting/nickname",
    data: data,
  );
}

class FriendVO {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final String userAccount;
  late final String? friendNickname; // 可空字段

  FriendVO({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.userAccount,
    this.friendNickname,
  });

  factory FriendVO.fromJson(Map<String, dynamic> json) {
    return FriendVO(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'] ??
          'https://fastly.jsdelivr.net/npm/@vant/assets/logo.png',
      userAccount: json['userAccount'] ?? '',
      friendNickname: json['friendNickname'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'userAccount': userAccount,
      'friendNickName': friendNickname,
    };
  }
}

Future<ApiResponse<List<FriendVO>>> getFriendListApi() async {
  return await HttpManager.get<List<FriendVO>>(
    "/friends/list",
    fromJson: (json) {
      if (json is List) {
        return json.map((item) => FriendVO.fromJson(item)).toList();
      }
      return [];
    },
  );
}

