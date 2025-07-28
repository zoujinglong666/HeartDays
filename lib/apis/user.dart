import 'package:heart_days/http/http_manager.dart';
import 'package:heart_days/http/model/api_response.dart';

class UserRegisterDto {
  final String userAccount;
  final String password;
  final String confirmPassword;

  UserRegisterDto({
    required this.userAccount,
    required this.password,
    required this.confirmPassword,
  });


  factory UserRegisterDto.fromJson(Map<String, dynamic> json) {
    return UserRegisterDto(
      userAccount: json['userAccount'],
      password: json['password'],
      confirmPassword: json['confirmPassword'],
    );
  }

}


class UserDto {
  final String? id;
  final String? name;
  final String? userAccount;
  final String? email; // 定义为可空类型
  final String? password;
  final String? avatar;
  final List<String>? roles;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserDto({
    this.id,
    this.name = '无名', // 提供默认值
    this.userAccount,
    this.email = '', // 空字符串默认值
    this.password,
    this.avatar,
    this.roles = const ['user'],
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  // 从 JSON 解析的工厂构造函数
  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id']?.toString(),
      name: json['name'] ?? '无名',
      userAccount: json['userAccount'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      avatar: json['avatar'],
      roles: (json['roles'] is List)
          ? List<String>.from(json['roles'])
          : const ['user'],
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

}

class LoginResponse {
  final String accessToken;
  final String? refreshToken; // 添加refreshToken字段
  final User user;

  LoginResponse({
    required this.accessToken,
    this.refreshToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'],
      refreshToken: json['refresh_token'], // 解析refreshToken
      user: User.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'refresh_token': refreshToken,
      'user': user.toJson(),
    };
  }
}

class User {
  final String id;
  final String name;
  final String userAccount;
  final String email;
  final String avatar;
  final int gender;
  final List<String> roles;

  User({
    this.id = '',
    this.name = '无名',
    this.userAccount = '',
    this.email = '',
    this.avatar = '',
    this.gender = 0,
    this.roles = const ['user'],
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '无名',
      userAccount: json['userAccount']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      avatar: json['avatar']?.toString() ?? '',
      gender: json['gender'] is int ? json['gender'] : 0,
      roles: (json['roles'] is List)
          ? List<String>.from(json['roles'].whereType<String>())
          : ['user'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'userAccount': userAccount,
      'email': email,
      'avatar': avatar,
      'gender': gender,
      'roles': roles,
    };
  }
}

Future<ApiResponse<UserDto>> userRegister(Map<String, dynamic> data) async {
  return await HttpManager.post<UserDto>(
    "/auth/register",
    data: data,
    fromJson: (json) => UserDto.fromJson(json),
  );
}
Future<ApiResponse<LoginResponse>> userLogin(Map<String, dynamic> data) async {
  return await HttpManager.post<LoginResponse>(
    "/auth/login",
    data: data,
    fromJson: (json) => LoginResponse.fromJson(json), // ✅ 保持一致
  );
}
Future<ApiResponse> userLogoutApi() async {
  return await HttpManager.post<LoginResponse>(
    "/auth/logout",
  );
}

Future<ApiResponse<User>> updateUser(Map<String, dynamic> data) async {
  return await HttpManager.post<User>(
    "/users/update",
    data: data,
    fromJson: (json) => User.fromJson(json), // ✅ 保持一致
  );
}

/// 强制登出其他设备
Future<ApiResponse<void>> forceLogoutOtherDevices() async {
  return await HttpManager.post<void>(
    "/auth/force-logout-others",
    data: {},
    fromJson: (json) => null,
  );
}
class RefreshTokenRequest {
  final String refreshToken;

  RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() => {
    'refresh_token': refreshToken,
  };
}
class UserVO {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final String userAccount;

  UserVO({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.userAccount,
  });

  factory UserVO.fromJson(Map<String, dynamic> json) {
    return UserVO(
      id: json['id'] ?? '',
      name: json['name'] ?? '无名',
      email: json['email'] ?? '',
      avatar: json['avatar'] ?? 'https://fastly.jsdelivr.net/npm/@vant/assets/logo.png',
      userAccount: json['userAccount'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'userAccount': userAccount,
    };
  }
}


/// 刷新token
Future<ApiResponse<Map<String, dynamic>>> refreshTokenApi(Map<String, dynamic> data) async {
  return await HttpManager.post<Map<String, dynamic>>(
    "/auth/refresh",
    data: data,
    fromJson: (json) => json,
  );
}
class UnaddedUserVO {
  final String id;
  final String name;
  final String email;
  final String avatar;
  final String userAccount;
  final String friendshipStatus;

  UnaddedUserVO({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    required this.userAccount,
    required this.friendshipStatus,
  });

  factory UnaddedUserVO.fromJson(Map<String, dynamic> json) {
    return UnaddedUserVO(
      id: json['id'] ?? '',
      name: json['name'] ?? '无名',
      email: json['email'] ?? '',
      avatar: json['avatar'] ?? 'https://fastly.jsdelivr.net/npm/@vant/assets/logo.png',
      userAccount: json['userAccount'] ?? '',
      friendshipStatus: json['friendshipStatus'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'userAccount': userAccount,
      'friendshipStatus': friendshipStatus,
    };
  }
}
/// 获取未添加的用户列表
Future<ApiResponse<List<UnaddedUserVO>>> listUnaddedUsers(Map<String, dynamic> data) async {
  return await HttpManager.get<List<UnaddedUserVO>>(
    "/users/unadded",
    queryParameters: data,
    fromJson: (json) {
      if (json is List) {
        return json.map((item) => UnaddedUserVO.fromJson(item)).toList();
      }
      return [];
    },
  );
}






