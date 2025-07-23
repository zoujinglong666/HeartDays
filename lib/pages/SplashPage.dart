import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heart_days/provider/auth_provider.dart';
import 'package:heart_days/services/ChatSocketService.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  String _loadingText = '正在启动...';
  int _loadingStep = 0;

  // 与登录页面保持一致的配色方案
  static const Color primaryColor = Color(0xFFF48FB1); // 更柔和的粉红色
  static const Color secondaryColor = Color(0xFFCE93D8); // 更柔和的紫色
  static const Color backgroundColor = Color(0xFFFEF7F9); // 更淡的粉色背景
  static const Color cardColor = Color(0xFFFFFFFF); // 纯白

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    try {
      // 快速检查：如果已经初始化，直接进入下一步
      if (ref.read(authProvider).isInitialized) {
        _updateLoadingState('检查登录状态...', 2);
        await Future.delayed(const Duration(milliseconds: 100)); // 最小延迟
      } else {
        // 步骤1: 等待初始化（减少等待时间）
        _updateLoadingState('正在初始化...', 1);
        await _waitForInitialization();

        // 步骤2: 检查登录状态（减少延迟）
        _updateLoadingState('检查登录状态...', 2);
        await Future.delayed(const Duration(milliseconds: 100)); // 进一步减少到100ms
      }

      final authState = ref.read(authProvider);

      // 步骤3: 导航到相应页面（减少延迟）
      _updateLoadingState('准备进入...', 3);
      await Future.delayed(const Duration(milliseconds: 50)); // 进一步减少到50ms

      if (authState.token != null && authState.user != null) {
        final userId = authState.user!.id;
        ChatSocketService().connect(authState.token!, userId);
        Navigator.of(context).pushReplacementNamed('/main');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      print('启动检查失败: $e');
      // 出错时默认跳转到登录页
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  Future<void> _waitForInitialization() async {
    int timeoutCount = 0;
    const maxTimeout = 40; // 从60减少到40，最多等待2秒 (40 * 50ms)
    const checkInterval = 30; // 减少检查间隔到30ms

    while (!ref.read(authProvider).isInitialized && timeoutCount < maxTimeout) {
      await Future.delayed(const Duration(milliseconds: checkInterval));
      timeoutCount++;

      // 每5次检查更新一次加载文本（更频繁更新）
      if (timeoutCount % 5 == 0) {
        _updateLoadingState('正在初始化... (${timeoutCount * checkInterval}ms)', 1);
      }
    }

    if (timeoutCount >= maxTimeout) {
      print('⚠️ 初始化超时，强制继续');
    }
  }

  void _updateLoadingState(String text, int step) {
    if (mounted) {
      setState(() {
        _loadingText = text;
        _loadingStep = step;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor, secondaryColor],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(Icons.favorite, size: 60, color: primaryColor),
            ),

            const SizedBox(height: 40),

            // App Name
            const Text(
              '甜甜纪念日',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: cardColor,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: 60),

            // Loading Indicator
            Column(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: const AlwaysStoppedAnimation<Color>(cardColor),
                  ),
                ),

                const SizedBox(height: 20),

                // Loading Text
                Text(
                  _loadingText,
                  style: const TextStyle(fontSize: 16, color: cardColor),
                ),

                const SizedBox(height: 10),

                // Progress Steps
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            index < _loadingStep
                                ? cardColor
                                : cardColor.withOpacity(0.3),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
