import 'package:flutter/material.dart';
import 'package:heart_days/components/simple_webView/index.dart';

class WebViewExample extends StatelessWidget {
  const WebViewExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebView 示例'),
        backgroundColor: const Color(0xFFF48FB1),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildExampleCard(
            context,
            '基础用法',
            '最简单的WebView使用',
            () => _openBasicWebView(context),
          ),
          _buildExampleCard(
            context,
            '带进度条',
            '显示加载进度',
            () => _openProgressWebView(context),
          ),
          _buildExampleCard(
            context,
            '自定义加载界面',
            '自定义加载和错误界面',
            () => _openCustomWebView(context),
          ),
          _buildExampleCard(
            context,
            '无导航栏',
            '隐藏顶部导航栏',
            () => _openNoNavWebView(context),
          ),
          _buildExampleCard(
            context,
            '带自定义头部',
            '添加自定义HTTP头部',
            () => _openCustomHeadersWebView(context),
          ),
          _buildExampleCard(
            context,
            '自定义错误界面',
            '测试自定义错误界面',
            () => _openCustomErrorWebView(context),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard(
    BuildContext context,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: const Icon(Icons.web, color: Color(0xFFF48FB1)),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  void _openBasicWebView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SimpleWebView(
          initialUrl: 'https://www.baidu.com',
          pageTitle: '百度',
        ),
      ),
    );
  }

  void _openProgressWebView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SimpleWebView(
          initialUrl: 'https://www.github.com',
          pageTitle: 'GitHub',
          showProgress: true,
          showRefresh: true,
        ),
      ),
    );
  }

  void _openCustomWebView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimpleWebView(
          initialUrl: 'https://www.google.com',
          pageTitle: 'Google',
          showProgress: true,
          loadingWidget: _buildCustomLoadingWidget(),
          errorWidget: _buildCustomErrorWidget(),
          onUrlChanged: (url) => print('URL changed: $url'),
          onTitleChanged: (title) => print('Title changed: $title'),
        ),
      ),
    );
  }

  void _openNoNavWebView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SimpleWebView(
          initialUrl: 'https://www.youtube.com',
          showNavBar: false,
        ),
      ),
    );
  }

  void _openCustomHeadersWebView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimpleWebView(
          initialUrl: 'https://httpbin.org/headers',
          pageTitle: '自定义头部测试',
          headers: {
            'User-Agent': 'MyApp/1.0',
            'X-Custom-Header': 'CustomValue',
          },
        ),
      ),
    );
  }

  void _openCustomErrorWebView(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SimpleWebView(
          initialUrl: 'https://invalid-url-that-will-fail.com', // 故意使用无效URL来触发错误
          pageTitle: '错误界面测试',
          showProgress: true,
          errorWidget: _buildCustomErrorWidget(),
        ),
      ),
    );
  }

  Widget _buildCustomLoadingWidget() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF48FB1)),
            ),
            const SizedBox(height: 16),
            Text(
              '正在加载页面...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '请稍候',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            const SizedBox(height: 16),
            Text(
              '网络连接失败',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '请检查网络连接后重试',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // 这里可以添加重试逻辑
              },
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF48FB1),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 高级用法示例
class AdvancedWebViewExample extends StatefulWidget {
  const AdvancedWebViewExample({super.key});

  @override
  State<AdvancedWebViewExample> createState() => _AdvancedWebViewExampleState();
}

class _AdvancedWebViewExampleState extends State<AdvancedWebViewExample> {
  String _currentUrl = '';
  String _currentTitle = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('高级WebView'),
        backgroundColor: const Color(0xFFF48FB1),
      ),
      body: Column(
        children: [
          // 状态信息
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('当前URL: $_currentUrl'),
                const SizedBox(height: 4),
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

            ),
          ),
        ],
      ),
    );
  }
} 