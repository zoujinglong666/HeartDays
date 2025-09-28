# 用户切换问题修复说明

## 问题描述
两台设备互换账号登录时，WebSocket连接仍然指向同一个账号，导致消息接收错乱。

## 问题原因
1. **单例模式状态残留**：ChatSocketService使用单例模式，用户切换时状态没有完全清理
2. **用户房间未正确切换**：没有离开旧用户房间，也没有加入新用户房间
3. **Token更新机制不完善**：用户完全切换时处理不够彻底

## 解决方案

### 1. 修改ChatSocketService.dart
- 添加`_currentUserId`字段跟踪当前连接的用户
- 新增`switchUser()`方法处理用户切换
- 新增`safeUserSwitch()`方法提供安全的用户切换
- 新增`reset()`方法完全重置服务状态
- 修改`connect()`方法检测用户切换

### 2. 新增UserSwitchHelper.dart
- 专门处理用户切换逻辑的辅助类
- 提供`onUserLogin()`、`onUserLogout()`等方法
- 统一管理WebSocket连接的用户切换

### 3. 新增UserSessionManager.dart
- 统一的用户会话管理器
- 管理用户登录状态和WebSocket连接
- 提供完整的用户生命周期管理

## 使用方法

### 在用户登录时
```dart
import 'package:heart_days/utils/UserSessionManager.dart';

// 用户登录成功后
await UserSessionManager().login(token, userId, userInfo: userInfo);
```

### 在用户登出时
```dart
// 用户登出时
await UserSessionManager().logout();
```

### 在应用启动时
```dart
// 在main.dart或应用初始化时
await UserSessionManager().initialize();
```

### 刷新token时
```dart
// 当获取到新token时
await UserSessionManager().refreshToken(newToken);
```

## 关键改进点

1. **用户房间管理**：
   - 切换用户时会先离开旧用户房间
   - 然后加入新用户房间

2. **状态完全清理**：
   - 断开连接时清理所有用户相关状态
   - 防止状态残留导致的问题

3. **安全切换机制**：
   - 检测用户变化时自动触发切换
   - 确保WebSocket连接与当前用户一致

4. **统一管理**：
   - 通过UserSessionManager统一管理用户状态
   - 简化用户切换的调用复杂度

## 测试建议

1. **两台设备互换登录测试**：
   - 设备A登录用户1，设备B登录用户2
   - 然后设备A登录用户2，设备B登录用户1
   - 验证消息接收是否正确

2. **快速切换测试**：
   - 在同一设备上快速切换不同用户
   - 验证WebSocket连接是否正确切换

3. **网络异常测试**：
   - 在用户切换过程中模拟网络异常
   - 验证重连机制是否正常工作

## 注意事项

1. 确保在用户登录/登出的关键节点调用相应方法
2. 如果有其他地方直接调用ChatSocketService，建议改为使用UserSessionManager
3. 可以根据实际需求调整状态清理的程度（是否清理回调函数等）