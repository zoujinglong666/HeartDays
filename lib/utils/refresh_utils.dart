import 'dart:async';

import 'package:flutter/material.dart';

/// 下拉刷新工具类
class RefreshUtils {
  /// 显示刷新提示
  static void showRefreshToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 模拟网络请求延迟
  static Future<void> simulateNetworkDelay([int milliseconds = 1000]) async {
    await Future.delayed(Duration(milliseconds: milliseconds));
  }

  /// 创建刷新回调函数
  static Future<void> Function() createRefreshCallback({
    required VoidCallback onRefresh,
    String? successMessage,
    String? errorMessage,
    BuildContext? context,
  }) {
    return () async {
      try {
        await simulateNetworkDelay();
        onRefresh();
        if (context != null && successMessage != null) {
          showRefreshToast(context, successMessage);
        }
      } catch (e) {
        if (context != null && errorMessage != null) {
          showRefreshToast(context, errorMessage);
        }
      }
    };
  }
}

/// 刷新状态管理
class RefreshState extends ChangeNotifier {
  bool _isRefreshing = false;
  DateTime? _lastRefreshTime;

  bool get isRefreshing => _isRefreshing;
  DateTime? get lastRefreshTime => _lastRefreshTime;

  /// 开始刷新
  void startRefresh() {
    _isRefreshing = true;
    notifyListeners();
  }

  /// 结束刷新
  void endRefresh() {
    _isRefreshing = false;
    _lastRefreshTime = DateTime.now();
    notifyListeners();
  }

  /// 执行刷新操作
  Future<void> performRefresh(Future<void> Function() refreshCallback) async {
    startRefresh();
    try {
      await refreshCallback();
    } finally {
      endRefresh();
    }
  }

  /// 获取最后刷新时间的格式化字符串
  String getLastRefreshTimeString() {
    if (_lastRefreshTime == null) return '从未刷新';
    
    final now = DateTime.now();
    final difference = now.difference(_lastRefreshTime!);
    
    if (difference.inMinutes < 1) {
      return '刚刚刷新';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前刷新';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前刷新';
    } else {
      return '${difference.inDays}天前刷新';
    }
  }
}

/// 自定义刷新指示器
class CustomRefreshIndicator extends StatelessWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? color;
  final Color? backgroundColor;
  final double strokeWidth;
  final String? refreshingText;
  final String? releaseText;

  const CustomRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
    this.backgroundColor,
    this.strokeWidth = 2.0,
    this.refreshingText,
    this.releaseText,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? Theme.of(context).primaryColor,
      backgroundColor: backgroundColor ?? Colors.white,
      strokeWidth: strokeWidth,
       notificationPredicate: (notification) {
        return notification is ScrollUpdateNotification &&
               notification.metrics.axis == Axis.vertical;
      },
      child: child,
    );
  }
}

/// 带加载状态的下拉刷新
class LoadingRefreshIndicator extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final Widget? loadingWidget;
  final Duration loadingDuration;
  final dynamic timeoutDuration;
  const LoadingRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.loadingWidget,
    this.loadingDuration = const Duration(milliseconds: 500),
  this.timeoutDuration = const Duration(seconds: 10), // ✅ 新增参数
  });

  @override
  State<LoadingRefreshIndicator> createState() => _LoadingRefreshIndicatorState();
}

class _LoadingRefreshIndicatorState extends State<LoadingRefreshIndicator> {
  bool _isLoading = false;

  Future<void> _handleRefresh() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // ✅ 设置超时 30 秒（可配置）
      await widget.onRefresh().timeout(
        widget.timeoutDuration,
        onTimeout: () => throw TimeoutException('刷新超时'),
      );
    } catch (e) {
      debugPrint('刷新出错: $e');
      // 可选：你可以在这里显示 SnackBar 或 Toast 提示用户
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is TimeoutException ? '刷新超时' : '刷新失败')),
      );
    } finally {
      await Future.delayed(widget.loadingDuration);
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: _handleRefresh,
          notificationPredicate: (notification) {
            return notification is ScrollUpdateNotification &&
                   notification.metrics.axis == Axis.vertical;
          },
          child: widget.child,
        ),
        if (_isLoading)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: widget.loadingWidget ?? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text(
                      '正在刷新...',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
} 