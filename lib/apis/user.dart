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
  final User user;

  LoginResponse({
    required this.accessToken,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'],
      user: User.fromJson(json['user']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
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
    this.gender=0,
    this.name = '无名',
    this.userAccount = '',
    this.email = '',
    this.avatar = '',
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
      'roles': roles,
      'gender': gender,
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
  return await HttpManager.post<LoginResponse>( // ✅ 改成 LoginResponse
    "/auth/login",
    data: data,
    fromJson: (json) => LoginResponse.fromJson(json), // ✅ 保持一致
  );
}


Future<ApiResponse<User>> updateUser(Map<String, dynamic> data) async {
  return await HttpManager.post<User>( // ✅ 改成 LoginResponse
    "/users/update",
    data: data,
    fromJson: (json) => User.fromJson(json), // ✅ 保持一致
  );
}



