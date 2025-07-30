class StartupMonitor {
  static final StartupMonitor _instance = StartupMonitor._internal();
  factory StartupMonitor() => _instance;
  StartupMonitor._internal();

  final Map<String, DateTime> _startTimes = {};
  final Map<String, DateTime> _endTimes = {};
  final List<String> _events = [];

  /// 开始监控一个阶段
  void startPhase(String phaseName) {
    _startTimes[phaseName] = DateTime.now();
    _events.add('🟢 开始: $phaseName');
    print('🟢 开始: $phaseName');
  }

  /// 结束监控一个阶段
  void endPhase(String phaseName) {
    _endTimes[phaseName] = DateTime.now();
    
    // 安全地获取开始时间，如果不存在则使用当前时间
    final startTime = _startTimes[phaseName];
    if (startTime != null) {
      final duration = _endTimes[phaseName]!.difference(startTime);
      _events.add('🔴 结束: $phaseName (耗时: ${duration.inMilliseconds}ms)');
      print('🔴 结束: $phaseName (耗时: ${duration.inMilliseconds}ms)');
    } else {
      _events.add('🔴 结束: $phaseName (开始时间未记录)');
      print('🔴 结束: $phaseName (开始时间未记录)');
    }
  }

  /// 记录一个事件
  void logEvent(String event) {
    _events.add('📝 $event');
    print('📝 $event');
  }

  /// 记录错误
  void logError(String error) {
    _events.add('❌ 错误: $error');
    print('❌ 错误: $error');
  }

  /// 获取启动报告
  String getStartupReport() {
    final buffer = StringBuffer();
    buffer.writeln('🚀 启动报告:');
    buffer.writeln('=' * 50);
    
    for (final event in _events) {
      buffer.writeln(event);
    }
    
    buffer.writeln('=' * 50);
    
    // 计算总耗时
    if (_startTimes.isNotEmpty && _endTimes.isNotEmpty) {
      final firstStart = _startTimes.values.reduce((a, b) => a.isBefore(b) ? a : b);
      final lastEnd = _endTimes.values.reduce((a, b) => a.isAfter(b) ? a : b);
      final totalDuration = lastEnd.difference(firstStart);
      buffer.writeln('⏱️ 总耗时: ${totalDuration.inMilliseconds}ms');
    }
    
    return buffer.toString();
  }

  /// 清除监控数据
  void clear() {
    _startTimes.clear();
    _endTimes.clear();
    _events.clear();
  }
} 