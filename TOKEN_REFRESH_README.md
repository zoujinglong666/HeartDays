# Token刷新功能实现说明

## 功能概述

本项目实现了完整的token刷新机制，包括：

1. **自动token刷新**: 当access token即将过期时自动刷新
2. **401错误处理**: 当收到401错误时自动尝试刷新token并重试请求
3. **token过期检测**: 定期检查token状态，提前刷新即将过期的token
4. **刷新失败处理**: 当refresh token过期时自动登出用户

## 核心组件

### 1. Token刷新拦截器 (`lib/http/interceptors/token_refresh_interceptor.dart`)

- **401错误拦截**: 拦截所有401错误并尝试刷新token
- **请求重试**: 刷新成功后自动重试原请求
- **防重复刷新**: 防止同一请求重复触发刷新

### 2. Token管理器 (`lib/utils/token_manager.dart`)

- **定时检查**: 每5分钟检查一次token状态
- **过期时间管理**: 管理access token和refresh token的过期时间
- **自动刷新**: 在token即将过期时自动刷新

### 3. 认证状态管理 (`lib/provider/auth_provider.dart`)

- **refreshToken支持**: 在登录状态中包含refresh token
- **刷新逻辑**: 实现token刷新逻辑
- **状态同步**: 刷新成功后同步更新本地存储

### 4. API接口扩展 (`lib/apis/user.dart`)

- `refreshToken()`: 刷新token的API接口
- `LoginResponse`: 支持refresh token的登录响应

## 工作流程

### 登录流程

1. 用户输入账号密码
2. 调用登录API，获取access token和refresh token
3. 保存token到本地存储
4. 启动token检查定时器

### 自动刷新流程

1. TokenManager每5分钟检查一次token状态
2. 如果access token即将过期（提前10分钟），自动刷新
3. 刷新成功后更新本地存储和状态
4. 触发刷新成功事件

### 401错误处理流程

1. 请求返回401错误
2. TokenRefreshInterceptor拦截错误
3. 检查是否在白名单中（登录、注册、刷新接口）
4. 尝试刷新token
5. 刷新成功后重试原请求
6. 刷新失败则触发登出

### 刷新失败处理

1. refresh token过期
2. 清除本地存储的token
3. 停止token检查定时器
4. 触发TokenExpiredEvent事件
5. 跳转到登录页面

## 服务器端要求

服务器需要实现以下API接口：

### 1. 登录接口 (`POST /auth/login`)

请求参数：
```json
{
  "userAccount": "用户名",
  "password": "密码",
  "deviceId": "设备唯一标识"
}
```

响应：
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

请求参数：
```json
{
  "refreshToken": "刷新令牌"
}
```

响应：
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

## 使用方法

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
final success = await ref.read(authProvider.notifier).refreshToken();
if (success) {
  print('Token刷新成功');
} else {
  print('Token刷新失败');
}
```

### 3. 检查token状态

```dart
final tokenManager = TokenManager(container);
final isExpiringSoon = await tokenManager.isTokenExpiringSoon();
```

## 配置说明

### 1. 定时检查间隔

在`TokenManager`中可以调整检查间隔：

```dart
// 每5分钟检查一次
_tokenCheckTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
  _checkTokenStatus();
});
```

### 2. 提前刷新时间

在`TokenManager`中可以调整提前刷新时间：

```dart
// 提前10分钟刷新
if (tokenExpiry != null && now + 600000 > tokenExpiry) {
  await _refreshTokenIfNeeded();
}
```

### 3. 白名单配置

在`TokenRefreshInterceptor`中可以配置不需要刷新token的接口：

```dart
const authWhitelist = [
  '/login',
  '/register',
  '/auth/refresh',
];
```

## 事件监听

### 1. Token刷新成功事件

```dart
eventBus.on<TokenRefreshSuccessEvent>().listen((event) {
  print('Token刷新成功: ${event.newAccessToken}');
});
```

### 2. Token刷新失败事件

```dart
eventBus.on<TokenRefreshFailedEvent>().listen((event) {
  print('Token刷新失败: ${event.reason}');
});
```

### 3. Token过期事件

```dart
eventBus.on<TokenExpiredEvent>().listen((event) {
  // 跳转到登录页面
  Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
});
```

## 注意事项

1. **网络异常处理**: 网络异常时不影响正常使用
2. **重复刷新防护**: 防止同一请求重复触发刷新
3. **定时器管理**: 应用退出时正确清理定时器
4. **用户体验**: 提供清晰的刷新状态提示

## 测试建议

1. **token过期测试**: 模拟token过期情况
2. **网络异常测试**: 模拟网络异常情况下的行为
3. **并发请求测试**: 测试多个请求同时触发刷新的情况
4. **refresh token过期测试**: 测试refresh token过期的情况

## 扩展功能

可以考虑添加以下扩展功能：

1. **token黑名单**: 支持token黑名单机制
2. **多设备token管理**: 支持多设备token同步
3. **token安全存储**: 使用更安全的token存储方式
4. **token使用统计**: 统计token使用情况 