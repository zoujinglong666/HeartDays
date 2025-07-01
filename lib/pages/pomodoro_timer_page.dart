import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PomodoroTimerPage extends StatefulWidget {
  const PomodoroTimerPage({super.key});

  @override
  State<PomodoroTimerPage> createState() => _PomodoroTimerPageState();
}

class _PomodoroTimerPageState extends State<PomodoroTimerPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  Timer? _timer;
  int _timeLeft = 25 * 60; // 25分钟
  int _totalTime = 25 * 60;
  bool _isRunning = false;
  bool _isBreak = false;
  int _completedSessions = 0;

  // 设置
  int _workTime = 25;
  int _breakTime = 5;
  int _longBreakTime = 15;
  int _sessionsBeforeLongBreak = 4;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  late AnimationController _animationController;
  late Animation<double> _animation;

  // 通知相关
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInBackground = false;
  bool _notificationShown = false; // 跟踪通知是否已显示

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    
    _initNotifications();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _stopNotification();
    // 清理完成通知
    _notifications.cancel(1);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _isInBackground = true;
      if (_isRunning && !_notificationShown) {
        _showNotification();
      }
    } else if (state == AppLifecycleState.resumed) {
      _isInBackground = false;
      _stopNotification();
    }
  }

  // 初始化通知
  Future<void> _initNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _notifications.initialize(initializationSettings);
    
    // 确保通知通道存在（Android 8.0+需要）
    await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
      const AndroidNotificationChannel(
        'pomodoro_timer',
        '番茄钟计时器',
        description: '显示番茄钟倒计时状态',
        importance: Importance.low,
      ),
    );
    
    await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
      const AndroidNotificationChannel(
        'pomodoro_completion',
        '番茄钟完成提醒',
        description: '专注时间或休息时间完成时的提醒',
        importance: Importance.high,
      ),
    );
  }

  // 显示通知
  Future<void> _showNotification() async {
    if (_notificationShown) return; // 防止重复显示
    
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'pomodoro_timer',
        '番茄钟计时器',
        channelDescription: '显示番茄钟倒计时状态',
        importance: Importance.low, // 降低重要性，避免打扰
        priority: Priority.low,
        ongoing: true, // 常驻通知
        autoCancel: false,
        showWhen: false,
        enableVibration: false,
        playSound: false,
        silent: true, // 静音
        onlyAlertOnce: true, // 防止重复提醒
      );
      
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      
      await _notifications.show(
        0,
        _isBreak ? '休息时间' : '专注时间',
        _formatTime(_timeLeft),
        platformChannelSpecifics,
      );
      
      _notificationShown = true;
    } catch (e) {
      print('显示通知失败: $e');
    }
  }

  // 更新通知内容（不重新创建通知）
  Future<void> _updateNotification() async {
    if (!_notificationShown || !_isInBackground || !_isRunning) return;
    
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'pomodoro_timer',
        '番茄钟计时器',
        channelDescription: '显示番茄钟倒计时状态',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
        showWhen: false,
        enableVibration: false,
        playSound: false,
        silent: true,
        onlyAlertOnce: true, // 防止重复提醒
      );
      
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      
      // 更新现有通知
      await _notifications.show(
        0,
        _isBreak ? '休息时间' : '专注时间',
        _formatTime(_timeLeft),
        platformChannelSpecifics,
      );
    } catch (e) {
      // 忽略更新错误，避免影响计时器
      print('通知更新失败: $e');
    }
  }

  // 停止通知
  Future<void> _stopNotification() async {
    await _notifications.cancel(0);
    _notificationShown = false;
  }

  void _startTimer() {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
    });

    _animationController.repeat();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
          // 在后台时，每秒更新通知（实时显示倒计时）
          if (_isInBackground) {
            _updateNotification();
          }
        } else {
          _timerComplete();
        }
      });
    });
  }

  void _pauseTimer() {
    setState(() {
      _isRunning = false;
    });

    _timer?.cancel();
    _animationController.stop();
    
    // 暂停时停止通知
    _stopNotification();
  }

  void _resetTimer() {
    setState(() {
      _isRunning = false;
      _timeLeft = _totalTime;
      _isBreak = false;
    });

    _timer?.cancel();
    _animationController.reset();
    
    // 重置时停止通知
    _stopNotification();
  }

  void _timerComplete() {
    _timer?.cancel();
    _animationController.stop();

    setState(() {
      _isRunning = false;
    });

    // 停止计时通知
    _stopNotification();

    // 显示完成通知
    _showCompletionNotification();

    // 播放声音和震动
    if (_soundEnabled) {
      HapticFeedback.mediumImpact();
    }
    if (_vibrationEnabled) {
      HapticFeedback.vibrate();
    }

    // 显示完成对话框
    _showTimerCompleteDialog();
  }

  // 显示完成通知
  Future<void> _showCompletionNotification() async {
    try {
      AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'pomodoro_completion',
        '番茄钟完成提醒',
        channelDescription: '专注时间或休息时间完成时的提醒',
        importance: Importance.high, // 高重要性，确保用户能看到
        priority: Priority.high,
        ongoing: false, // 非常驻通知
        autoCancel: true,
        showWhen: true,
        enableVibration: _vibrationEnabled,
        playSound: _soundEnabled,
        silent: false, // 允许声音
        onlyAlertOnce: false, // 允许重复提醒
        category: AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
      );
      
      NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      
      String title = _isBreak ? '休息时间结束！' : '专注时间结束！';
      String body = _isBreak 
          ? '休息时间已结束，准备开始下一轮专注吧！'
          : '恭喜完成一个专注周期！现在休息一下吧。';
      
      await _notifications.show(
        1, // 使用不同的ID，避免与计时通知冲突
        title,
        body,
        platformChannelSpecifics,
      );
    } catch (e) {
      print('显示完成通知失败: $e');
    }
  }

  void _showTimerCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _isBreak ? '休息时间结束！' : '专注时间结束！',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        content: Text(
          _isBreak
              ? '休息时间已结束，准备开始下一轮专注吧！'
              : '恭喜完成一个专注周期！现在休息一下吧。',
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF666666),
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _startNextSession();
            },
            child: const Text(
              '开始下一轮',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF007AFF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startNextSession() {
    if (_isBreak) {
      // 休息结束，开始工作
      setState(() {
        _isBreak = false;
        _completedSessions++;
        _timeLeft = _workTime * 60;
        _totalTime = _workTime * 60;
      });
    } else {
      // 工作结束，开始休息
      setState(() {
        _isBreak = true;
        // 判断是否应该长休息
        if (_completedSessions % _sessionsBeforeLongBreak == 0) {
          _timeLeft = _longBreakTime * 60;
          _totalTime = _longBreakTime * 60;
        } else {
          _timeLeft = _breakTime * 60;
          _totalTime = _breakTime * 60;
        }
      });
    }
    
    // 如果在后台，更新通知状态
    if (_isInBackground && _notificationShown) {
      _updateNotification();
    }
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSettingsSheet(),
    );
  }


  Future<int?> _showTimePickerDialog({required String title, required int value, required List<int> options}) async {
    int tempValue = value;
    return showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('选择时间（分钟）: $tempValue', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: options.map((minutes) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: GestureDetector(
                          onTap: () {
                            setDialogState(() { tempValue = minutes; });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: minutes == tempValue ? const Color(0xFFFF6B6B) : const Color(0xFFFF6B6B).withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('$minutes', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, tempValue),
                child: const Text('确定', style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<int?> _showSessionsPickerDialog({required int value}) async {
    int tempValue = value;
    return showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('设置长休息间隔', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('选择周期数: $tempValue', style: const TextStyle(fontSize: 16, color: Color(0xFF666666))),
                const SizedBox(height: 20),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [2, 3, 4, 5, 6].map((sessions) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5.0),
                        child: GestureDetector(
                          onTap: () { setDialogState(() { tempValue = sessions; }); },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: sessions == tempValue ? const Color(0xFFFF6B6B) : const Color(0xFFFF6B6B).withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('$sessions', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, tempValue),
                child: const Text('确定', style: TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _onWorkTimeTap() async {
    final result = await _showTimePickerDialog(title: '设置专注时间', value: _workTime, options: [15, 20, 25, 30, 45, 60]);
    if (result != null && result != _workTime) {
      setState(() {
        _workTime = result;
        if (!_isRunning && !_isBreak) {
          _timeLeft = result * 60;
          _totalTime = result * 60;
        }
      });
    }
  }
  void _onBreakTimeTap() async {
    final result = await _showTimePickerDialog(title: '设置休息时间', value: _breakTime, options: [5, 10, 15, 20]);
    if (result != null && result != _breakTime) {
      setState(() {
        _breakTime = result;
        if (!_isRunning && _isBreak) {
          _timeLeft = result * 60;
          _totalTime = result * 60;
        }
      });
    }
  }
  void _onLongBreakTimeTap() async {
    final result = await _showTimePickerDialog(title: '设置长休息时间', value: _longBreakTime, options: [10, 15, 20, 25, 30]);
    if (result != null && result != _longBreakTime) {
      setState(() {
        _longBreakTime = result;
      });
    }
  }
  void _onSessionsTap() async {
    final result = await _showSessionsPickerDialog(value: _sessionsBeforeLongBreak);
    if (result != null && result != _sessionsBeforeLongBreak) {
      setState(() {
        _sessionsBeforeLongBreak = result;
      });
    }
  }

  Widget _buildSettingsSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              '专注设置',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              key: ValueKey(
                  'settings_${_soundEnabled}_${_vibrationEnabled}_${_workTime}_${_breakTime}_${_longBreakTime}_${_sessionsBeforeLongBreak}'
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildSettingItem('专注时间', '$_workTime 分钟', _onWorkTimeTap),
                _buildSettingItem('短休息时间', '$_breakTime 分钟', _onBreakTimeTap),
                _buildSettingItem('长休息时间', '$_longBreakTime 分钟', _onLongBreakTimeTap),
                _buildSettingItem('长休息间隔', '$_sessionsBeforeLongBreak 个周期', _onSessionsTap),
                const SizedBox(height: 20),
                _buildSwitchItem(
                  title: '声音提醒',
                  value: _soundEnabled,
                  onChanged: (val) {
                    setState(() {
                      _soundEnabled = val;
                    });
                  },
                ),
                _buildSwitchItem(
                  title: '震动提醒',
                  value: _vibrationEnabled,
                  onChanged: (val) {
                    setState(() {
                      _vibrationEnabled = val;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, String value, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFFFF6B6B), // 修改为番茄红色
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF8E8E93),
              size: 16,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSwitchItem({
    required String title,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: const Color(0xFFF8F9FA),
        child: ListTile(
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1A1A1A),
            ),
          ),
          trailing: Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFFF6B6B),
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  double _getProgress() {
    return (_totalTime - _timeLeft) / _totalTime;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          '专注计时',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Color(0xFF007AFF)),
            onPressed: _showSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 状态指示
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _isBreak
                          ? const Color(0xFF34C759).withOpacity(0.1)
                          : const Color(0xFFFF6B6B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _isBreak ? '休息时间' : '专注时间',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _isBreak
                            ? const Color(0xFF34C759)
                            : const Color(0xFFFF6B6B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 进度圆环
                  SizedBox(
                    width: 280,
                    height: 280,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // 背景圆环
                        SizedBox(
                          width: 280,
                          height: 280,
                          child: CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 16,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _isBreak
                                  ? const Color(0xFF34C759).withOpacity(0.2)
                                  : const Color(0xFFFF6B6B).withOpacity(0.2),
                            ),
                          ),
                        ),
                        // 进度圆环
                        SizedBox(
                          width: 280,
                          height: 280,
                          child: AnimatedBuilder(
                            animation: _animation,
                            builder: (context, child) {
                              return CircularProgressIndicator(
                                value: _getProgress(),
                                strokeWidth: 16,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _isBreak
                                      ? const Color(0xFF34C759)
                                      : const Color(0xFFFF6B6B),
                                ),
                              );
                            },
                          ),
                        ),
                        // 时间显示
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatTime(_timeLeft),
                              style: TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: _isBreak
                                    ? const Color(0xFF34C759)
                                    : const Color(0xFFFF6B6B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isBreak ? '休息一下' : '保持专注',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 控制按钮
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 重置按钮
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: _resetTimer,
                          icon: const Icon(
                            Icons.refresh,
                            color: Color(0xFF8E8E93),
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),

                      // 开始/暂停按钮
                      Container(
                        decoration: BoxDecoration(
                          color: _isBreak
                              ? const Color(0xFF34C759)
                              : const Color(0xFFFF6B6B),
                          borderRadius: BorderRadius.circular(50),
                          boxShadow: [
                            BoxShadow(
                              color: (_isBreak
                                  ? const Color(0xFF34C759)
                                  : const Color(0xFFFF6B6B)).withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: _isRunning ? _pauseTimer : _startTimer,
                          icon: Icon(
                            _isRunning ? Icons.pause : Icons.play_arrow,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}



