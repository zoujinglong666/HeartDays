import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heart_days/components/AnimatedGradientLinearProgress.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SimpleWebView extends StatefulWidget {
  final String initialUrl;
  final String? pageTitle;
  final bool? showNavBar;
  final bool? showBackIcon;
  final bool? showRefresh;
  final bool? showProgress;
  final bool? enableJavaScript;
  final bool? enableZoom;
  final Map<String, String>? headers;
  final Function(String)? onUrlChanged;
  final Function(String)? onTitleChanged;
  final Widget? loadingWidget;
  final Widget? errorWidget; // 新增：自定义错误界面

  const SimpleWebView({
    super.key,
    required this.initialUrl,
    this.pageTitle,
    this.showNavBar,
    this.showBackIcon,
    this.showRefresh,
    this.showProgress,
    this.enableJavaScript,
    this.enableZoom,
    this.headers,
    this.onUrlChanged,
    this.onTitleChanged,
    this.loadingWidget,
    this.errorWidget, // 新增参数
  });

  @override
  State<SimpleWebView> createState() => _SimpleWebViewState();
}

class _SimpleWebViewState extends State<SimpleWebView> {
  late final WebViewController _controller;
  String _currentTitle = '';
  String _currentUrl = '';
  bool _isLoading = true;
  bool _hasError = false; // 新增：错误状态
  String _errorMessage = ''; // 新增：错误信息
  double _progress = 0.0;
  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
    _initSystemUI();
    _initializeWebView();
  }

  void _initSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
    );
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(
        widget.enableJavaScript != false
            ? JavaScriptMode.unrestricted
            : JavaScriptMode.disabled,
      )
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _hasError = false; // 重置错误状态
              _errorMessage = '';
              _progress = 0.0;
            });
            widget.onUrlChanged?.call(url);
          },
          onProgress: (progress) {
            setState(() {
              _progress = progress / 100;
            });
          },
          onPageFinished: (url) async {
            setState(() {
              _isLoading = false;
              _hasError = false;
              _currentUrl = url;
            });

            // 可选：增强空内容检测
            try {
              final content = await _controller.runJavaScriptReturningResult(
                "document.body.innerText.trim()",
              );

              if ((content as String).isEmpty) {
                setState(() {
                  _hasError = true;
                  _errorMessage = '页面加载内容为空';
                });
              }
            } catch (_) {
              // JS 执行失败忽略
            }

            _getTitle();
            _checkNavigationState();
            widget.onUrlChanged?.call(url);
          },
          onWebResourceError: (WebResourceError error) {
            final isMainFrame = error.isForMainFrame ?? true; // iOS 上 null 默认 true
            if (isMainFrame && _shouldShowCustomError(error.errorType!)) {
              setState(() {
                _isLoading = false;
                _hasError = true;
                _errorMessage = _getErrorMessage(error);
              });
            }
          },

          onNavigationRequest: (request) => NavigationDecision.navigate,
        ),
      )
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (message) => _handleJSMessage(message.message),
      );

    _loadUrl();
  }

  // 新增：判断是否应该显示自定义错误界面
  bool _shouldShowCustomError(WebResourceErrorType errorType) {
    switch (errorType) {
      case WebResourceErrorType.timeout:
        return true; // 连接超时
      case WebResourceErrorType.hostLookup:
        return true; // 无法连接到服务器
      case WebResourceErrorType.unknown:
        return true; // 未知错误（通常是网络问题）
      case WebResourceErrorType.badUrl:
        return true; // 无效的网址
      case WebResourceErrorType.failedSslHandshake:
        return true; // SSL证书验证失败
      case WebResourceErrorType.tooManyRequests:
        return true; // 请求过于频繁
      case WebResourceErrorType.redirectLoop:
        return true; // 重定向循环
      default:
        return false; // 其他错误类型不显示自定义错误界面
    }
  }

  // 新增：获取错误信息
  String _getErrorMessage(WebResourceError error) {
    switch (error.errorType) {
      case WebResourceErrorType.unknown:
        return '网络连接异常，请检查网络设置';
      case WebResourceErrorType.badUrl:
        return '网址格式错误，请检查链接是否正确';
      case WebResourceErrorType.timeout:
        return '连接超时，请检查网络连接后重试';
      case WebResourceErrorType.hostLookup:
        return '无法连接到服务器，请检查网络连接';
      case WebResourceErrorType.failedSslHandshake:
        return '安全连接失败，请检查网络设置';
      case WebResourceErrorType.tooManyRequests:
        return '请求过于频繁，请稍后再试';
      case WebResourceErrorType.redirectLoop:
        return '页面重定向异常，请稍后重试';
      default:
        return '加载失败，请检查网络连接';
    }
  }

  // 新增：重试加载
  void _retry() {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
      _progress = 0.0;
    });
    _loadUrl();
  }

  Future<void> _loadUrl() async {
    try {
      final uri = Uri.parse(widget.initialUrl);
      final noCacheUrl = uri.replace(queryParameters: {
        ...uri.queryParameters,
        '_ts': DateTime.now().millisecondsSinceEpoch.toString(),
      });
      await _controller.loadRequest(
        noCacheUrl,
        headers: widget.headers ?? {},
      );
    } catch (_) {}
  }

  Future<void> _getTitle() async {
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final rawTitle = await _controller.getTitle();
      if (!mounted) return;

      final title = rawTitle?.trim();
      final isValid = _isValidTitle(title);
      final newTitle = isValid ? title : (widget.pageTitle ?? '');

      if (newTitle != _currentTitle) {
        setState(() {
          _currentTitle = newTitle!;
        });
        widget.onTitleChanged?.call(newTitle!);
      }
    } catch (_) {}
  }

  bool _isValidTitle(String? title) {
    if (title == null || title.isEmpty) return false;
    final isUrl = RegExp(r'^https?:\/\/[\w\.-]+').hasMatch(title);
    final hasSpecialChars = title.contains("http") || title.contains("www") || title.length < 2;
    return !isUrl && !hasSpecialChars;
  }

  Future<void> _checkNavigationState() async {
    final back = await _controller.canGoBack();
    final forward = await _controller.canGoForward();
    if (mounted) {
      setState(() {
        _canGoBack = back;
        _canGoForward = forward;
      });
    }
  }

  void _handleJSMessage(String message) {
    try {
      final data = jsonDecode(message);
      final action = data['action'];
      switch (action) {
        case 'openNewWebView':
          final url = data['url'];
          final title = data['title'];
          final showNavBar = data['showNavBar'];
          if (url != null && url.toString().isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SimpleWebView(
                  initialUrl: url,
                  pageTitle: title,
                  showNavBar: showNavBar ?? false,
                ),
              ),
            );
          }
          break;
        case 'goBack':
          Navigator.pop(context);
          break;
        case 'reload':
          _controller.reload();
          break;
      }
    } catch (_) {}
  }

  void _goBack() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
    } else {
      Navigator.pop(context);
    }
  }

  // 新增：处理手势返回
  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false; // 阻止默认的返回行为
    }
    return true; // 允许默认的返回行为
  }

  void _goForward() async {
    if (await _controller.canGoForward()) {
      _controller.goForward();
    }
  }

  void _reload() => _controller.reload();

  Future<void> _openInBrowser() async {

  }

  @override
  Widget build(BuildContext context) {
    final showNav = widget.showNavBar != false;
    final showBackIcon = widget.showBackIcon != false;
    final showRefresh = widget.showRefresh != false;
    final showProgress = widget.showProgress != false;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: showNav ? _buildAppBar(showBackIcon, showRefresh) : null,
        body: SafeArea(
          top: !showNav,
          child: Container(
            color: Colors.white,
            child: Stack(
              children: [
                if (!_hasError) WebViewWidget(controller: _controller),
                if (showProgress && _isLoading && !_hasError && _progress < 1.0)
                  _buildProgressBar(),
                if (_isLoading && !showProgress && !_hasError)
                  _buildLoadingIndicator(),
                if (_hasError) _buildErrorWidget(), // 放最后一层，遮住 webview
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool showBackIcon, bool showRefresh) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(48),
      child: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.white,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        leading: showBackIcon ? _buildBackButton() : null,
        centerTitle: true,
        title: _buildTitle(),
        actions: _buildActions(showRefresh),
      ),
    );
  }

  Widget _buildBackButton() {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.black),
      onPressed: _goBack,
    );
  }

  Widget _buildTitle() {
    return Text(
      _currentTitle.isNotEmpty ? _currentTitle : (widget.pageTitle ?? ''),
      style: const TextStyle(
        color: Colors.black,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  List<Widget> _buildActions(bool showRefresh) {
    final actions = <Widget>[];

    if (_canGoForward) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.arrow_forward, color: Colors.black),
          onPressed: _goForward,
        ),
      );
    }

    if (showRefresh) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.black),
          onPressed: _reload,
        ),
      );
    }

    actions.add(
      PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.black),
        onSelected: (value) {
          switch (value) {
            case 'reload':
              _reload();
              break;
            case 'copy_url':
              Clipboard.setData(ClipboardData(text: _currentUrl));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('链接已复制')),
              );
              break;
            case 'open_browser':
              _openInBrowser();
              break;
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'reload',
            child: Row(
              children: [Icon(Icons.refresh), SizedBox(width: 8), Text('刷新')],
            ),
          ),
          const PopupMenuItem(
            value: 'copy_url',
            child: Row(
              children: [Icon(Icons.copy), SizedBox(width: 8), Text('复制链接')],
            ),
          ),
          const PopupMenuItem(
            value: 'open_browser',
            child: Row(
              children: [Icon(Icons.open_in_browser), SizedBox(width: 8), Text('在浏览器打开')],
            ),
          ),
        ],
      ),
    );

    return actions;
  }

  Widget _buildProgressBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child:AnimatedGradientLinearProgress(
        value: _progress,
        backgroundColor: Colors.grey.shade200,
      )
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: widget.loadingWidget ??
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A90E2)),
              ),
              const SizedBox(height: 16),
              Text(
                '加载中...',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: widget.errorWidget ??
          Column(
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
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _retry,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
    );
  }
}
