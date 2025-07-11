# Token刷新功能实现总结

## 🎯 已实现的功能

### 1. 核心组件

✅ **Token刷新拦截器** (`lib/http/interceptors/token_refresh_interceptor.dart`)
- 拦截401错误并自动刷新token
- 刷新成功后重试原请求
- 防止重复刷新机制

✅ **Token管理器** (`lib/utils/token_manager.dart`)
- 定时检查token状态（每5分钟）
- 提前10分钟自动刷新即将过期的token
- 管理token过期时间

✅ **认证状态管理** (`lib/provider/auth_provider.dart`)
- 支持refresh token存储
- 实现token刷新逻辑
- 集成TokenManager

✅ **API接口扩展** (`lib/apis/user.dart`)
- 添加刷新token的API接口
- 支持refresh token的登录响应

### 2. 工作流程

#### 登录流程
1. 用户输入账号密码
2. 调用登录API，获取access token和refresh token
3. 保存token到本地存储
4. 启动token检查定时器

#### 自动刷新流程
1. TokenManager每5分钟检查一次token状态
2. 如果access token即将过期（提前10分钟），自动刷新
3. 刷新成功后更新本地存储和状态
4. 触发刷新成功事件

#### 401错误处理流程
1. 请求返回401错误
2. TokenRefreshInterceptor拦截错误
3. 检查是否在白名单中（登录、注册、刷新接口）
4. 尝试刷新token
5. 刷新成功后重试原请求
6. 刷新失败则触发登出

### 3. 事件系统

✅ **Token刷新成功事件**
```dart
eventBus.on<TokenRefreshSuccessEvent>().listen((event) {
  print('Token刷新成功: ${event.newAccessToken}');
});
```

✅ **Token刷新失败事件**
```dart
eventBus.on<TokenRefreshFailedEvent>().listen((event) {
  print('Token刷新失败: ${event.reason}');
});
```

✅ **Token过期事件**
```dart
eventBus.on<TokenExpiredEvent>().listen((event) {
  // 跳转到登录页面
});
```

## 🔧 使用方法

### 1. 登录时使用
```dart
final response = await userLoginWithDevice({
  "userAccount": username,
  "password": password,
}, deviceId);

if (response.code == 200) {
  final user = response.data?.user;
  final token = response.data?.accessToken;
  final refreshToken = response.data?.refreshToken;
  
  await ref.read(authProvider.notifier).login(
    user, 
    token,
    refreshToken: refreshToken,
  );
}
```

### 2. 手动刷新token
```dart
final success = await ref.read(authProvider.notifier).refreshAccessToken();
if (success) {
  print('Token刷新成功');
} else {
  print('Token刷新失败');
}
```

### 3. 检查token状态
```dart
final tokenManager = TokenManager(ref);
final isExpiringSoon = await tokenManager.isTokenExpiringSoon();
```

## 📋 服务器端要求

### 1. 登录接口 (`POST /auth/login`)
```json
{
  "code": 200,
  "data": {
    "access_token": "访问令牌",
    "refresh_token": "刷新令牌",
    "access_token_expiry": 1640995200000,
    "refresh_token_expiry": 1643587200000,
    "user": {
      "id": "用户ID",
      "name": "用户名",
      "userAccount": "账号"
    }
  }
}
```

### 2. 刷新token接口 (`POST /auth/refresh`)
```json
{
  "code": 200,
  "data": {
    "accessToken": "新的访问令牌",
    "refreshToken": "新的刷新令牌",
    "accessTokenExpiry": 1640995200000,
    "refreshTokenExpiry": 1643587200000
  }
}
```

## 🚀 配置说明

### 1. 定时检查间隔
```dart
// 每5分钟检查一次
_tokenCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
  _checkTokenStatus();
});
```

### 2. 提前刷新时间
```dart
// 提前10分钟刷新
if (tokenExpiry != null && now + 600000 > tokenExpiry) {
  await _refreshTokenIfNeeded();
}
```

### 3. 白名单配置
```dart
const authWhitelist = [
  '/login',
  '/register',
  '/auth/refresh',
];
```

## ✅ 测试功能

使用 `TokenRefreshTest` 类来测试token刷新功能：

```dart
TokenRefreshTest.testTokenRefresh(ref);
```

## 🎉 总结

✅ **已完成的功能**：
- 自动token刷新
- 401错误处理
- token过期检测
- 刷新失败处理
- 完整的事件系统
- 本地存储管理

✅ **用户体验**：
- 无感知的token刷新
- 清晰的错误提示
- 自动重试机制
- 防重复刷新

✅ **安全性**：
- token过期时间管理
- 刷新失败自动登出
- 白名单机制
- 异常处理

这个实现确保了用户的无缝体验，token过期时不会影响正常使用，同时保持了安全性。 