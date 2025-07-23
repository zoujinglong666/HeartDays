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

Future<ApiResponse<List<UserVO>>> getFriendListApi() async {
  return await HttpManager.get<List<UserVO>>(
    "/friends/list",
    fromJson: (json) {
      if (json is List) {
        return json.map((item) => UserVO.fromJson(item)).toList();
      }
      return [];
    },
  );
}

