typedef EventCallback = void Function(dynamic payload);

class EventBus {
  // 单例
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  final Map<String, List<EventCallback>> _listeners = {};

  /// 监听事件
  void on(String eventName, EventCallback callback) {
    _listeners[eventName] ??= [];
    _listeners[eventName]!.add(callback);
  }

  /// 移除事件监听
  void off(String eventName, [EventCallback? callback]) {
    if (callback == null) {
      _listeners.remove(eventName);
    } else {
      _listeners[eventName]?.remove(callback);
    }
  }

  /// 触发事件
  void emit(String eventName, [dynamic payload]) {
    final callbacks = _listeners[eventName];
    if (callbacks == null) return;
    for (final cb in List.of(callbacks)) {
      cb(payload);
    }
  }
}

// 提供一个全局实例
final eventBus = EventBus();
