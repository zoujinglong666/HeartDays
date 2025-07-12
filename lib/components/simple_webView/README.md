# SimpleWebView 组件

一个功能完善、易于使用的Flutter WebView组件，支持多种自定义选项和回调函数。

## 特性

- ✅ **加载状态管理** - 自动处理加载、错误状态
- ✅ **进度条显示** - 可选的加载进度条
- ✅ **自定义界面** - 支持自定义加载和错误界面
- ✅ **导航控制** - 前进、后退、刷新功能
- ✅ **JavaScript支持** - 可配置JavaScript启用/禁用
- ✅ **自定义头部** - 支持添加HTTP请求头
- ✅ **事件回调** - URL变化、标题变化、错误处理
- ✅ **更多功能** - 复制链接、在浏览器中打开等

## 基本用法

```dart
import 'package:heart_days/components/simple_webView/index.dart';

// 最简单的用法
SimpleWebView(
  initialUrl: 'https://www.example.com',
  pageTitle: '示例页面',
)
```

## 参数说明

### 必需参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `initialUrl` | `String` | 初始加载的URL |

### 可选参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `pageTitle` | `String?` | `null` | 页面标题 |
| `showNavBar` | `bool?` | `true` | 是否显示导航栏 |
| `showBackIcon` | `bool?` | `true` | 是否显示返回按钮 |
| `showRefresh` | `bool?` | `true` | 是否显示刷新按钮 |
| `showProgress` | `bool?` | `false` | 是否显示进度条 |
| `enableJavaScript` | `bool?` | `true` | 是否启用JavaScript |
| `enableZoom` | `bool?` | `true` | 是否启用缩放 |
| `headers` | `Map<String, String>?` | `null` | 自定义HTTP头部 |
| `loadingWidget` | `Widget?` | `null` | 自定义加载界面 |
| `errorWidget` | `Widget?` | `null` | 自定义错误界面 |

### 回调函数

| 参数 | 类型 | 说明 |
|------|------|------|
| `onUrlChanged` | `Function(String)?` | URL变化回调 |
| `onTitleChanged` | `Function(String)?` | 标题变化回调 |
| `onError` | `Function(String)?` | 错误回调 |

## 使用示例

### 1. 基础用法

```dart
SimpleWebView(
  initialUrl: 'https://www.baidu.com',
  pageTitle: '百度',
)
```

### 2. 带进度条

```dart
SimpleWebView(
  initialUrl: 'https://www.github.com',
  pageTitle: 'GitHub',
  showProgress: true,
  showRefresh: true,
)
```

### 3. 自定义界面

```dart
SimpleWebView(
  initialUrl: 'https://www.google.com',
  pageTitle: 'Google',
  showProgress: true,
  loadingWidget: _buildCustomLoadingWidget(),
  errorWidget: _buildCustomErrorWidget(),
  onUrlChanged: (url) => print('URL changed: $url'),
  onTitleChanged: (title) => print('Title changed: $title'),
  onError: (error) => print('Error: $error'),
)
```

### 4. 无导航栏

```dart
SimpleWebView(
  initialUrl: 'https://www.youtube.com',
  showNavBar: false,
)
```

### 5. 自定义头部

```dart
SimpleWebView(
  initialUrl: 'https://httpbin.org/headers',
  pageTitle: '自定义头部测试',
  headers: {
    'User-Agent': 'MyApp/1.0',
    'X-Custom-Header': 'CustomValue',
  },
)
```

### 6. 高级用法

```dart
class MyWebViewPage extends StatefulWidget {
  @override
  _MyWebViewPageState createState() => _MyWebViewPageState();
}

class _MyWebViewPageState extends State<MyWebViewPage> {
  String _currentUrl = '';
  String _currentTitle = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('WebView')),
      body: Column(
        children: [
          // 状态信息
          Container(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text('当前URL: $_currentUrl'),
                Text('当前标题: $_currentTitle'),
              ],
            ),
          ),
          
          // WebView
          Expanded(
            child: SimpleWebView(
              initialUrl: 'https://www.example.com',
              showProgress: true,
              showRefresh: true,
              onUrlChanged: (url) {
                setState(() {
                  _currentUrl = url;
                });
              },
              onTitleChanged: (title) {
                setState(() {
                  _currentTitle = title;
                });
              },
              onError: (error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('加载失败: $error')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

## 自定义界面示例

### 自定义加载界面

```dart
Widget _buildCustomLoadingWidget() {
  return Container(
    color: Colors.white,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
          ),
          SizedBox(height: 16),
          Text(
            '正在加载页面...',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    ),
  );
}
```

### 自定义错误界面

```dart
Widget _buildCustomErrorWidget() {
  return Container(
    color: Colors.white,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.signal_wifi_off,
            size: 64,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            '网络连接失败',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '请检查网络连接后重试',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              // 重试逻辑
            },
            icon: Icon(Icons.refresh),
            label: Text('重试'),
          ),
        ],
      ),
    ),
  );
}
```

## JavaScript 通信

组件支持与网页进行JavaScript通信：

```dart
// 在网页中调用Flutter方法
window.FlutterBridge.postMessage(JSON.stringify({
  action: 'openNewWebView',
  url: 'https://example.com',
  title: '新页面',
  showNavBar: true
}));

// 在Flutter中处理消息
void _handleJSMessage(String message) {
  final data = jsonDecode(message);
  final action = data['action'];
  
  switch (action) {
    case 'openNewWebView':
      // 处理打开新WebView
      break;
    case 'goBack':
      // 处理返回
      break;
    case 'reload':
      // 处理刷新
      break;
  }
}
```

## 注意事项

1. **权限配置**：确保在Android和iOS配置文件中添加了网络权限
2. **HTTPS支持**：对于HTTPS网站，可能需要配置网络安全策略
3. **内存管理**：组件会自动处理资源清理，无需手动释放
4. **错误处理**：建议始终提供错误回调来处理加载失败的情况

## 依赖

确保在`pubspec.yaml`中添加了webview_flutter依赖：

```yaml
dependencies:
  webview_flutter: ^5.0.0
```

## 更新日志

### v2.0.0
- ✅ 添加进度条显示
- ✅ 添加错误处理界面
- ✅ 添加自定义加载界面
- ✅ 添加更多导航功能
- ✅ 添加自定义HTTP头部支持
- ✅ 添加事件回调函数
- ✅ 优化性能和用户体验 