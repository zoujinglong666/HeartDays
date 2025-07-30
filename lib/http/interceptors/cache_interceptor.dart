import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:heart_days/Consts/index.dart';
import 'package:heart_days/common/helper.dart';

final class CacheInterceptor extends Interceptor {
  bool _shouldCache = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method.toUpperCase() != "GET") {
      return handler.next(options);
    }

    final cacheKey = options.uri;
    final cacheManager = CacheManager.instance;

    if (cacheManager.contains(cacheKey)) {
      final cachedObject = cacheManager.get(cacheKey);
      final isExpired = Helper.timestamp() - cachedObject.timestamp >
          Consts.request.cachedTime.inMilliseconds;

      if (!isExpired) {
        debugPrint("📦 [缓存命中] -> $cacheKey");
        return handler.resolve(cachedObject.data);
      }

      debugPrint("♻️ [缓存过期，清理] -> $cacheKey");
      cacheManager.remove(cacheKey);
    }

    _shouldCache = true;
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (_shouldCache) {
      final key = response.requestOptions.uri;
      debugPrint("✅ [缓存写入] -> $key");
      CacheManager.instance.set(key, response);
    }

    _shouldCache = false; // 重置状态
    handler.next(response);
  }
}
class CacheObject {
  final Response data;
  final int timestamp;

  const CacheObject(this.data, this.timestamp);
}

class CacheManager {
  CacheManager._internal();
  static final CacheManager instance = CacheManager._internal();

  final Map<Uri, CacheObject> _cache = {};

  /// ✅ 是否存在缓存
  bool contains(Uri key) => _cache.containsKey(key);

  /// ✅ 获取缓存对象（请确保 contains 为 true 再调用）
  CacheObject get(Uri key) => _cache[key]!;

  /// ✅ 写入缓存
  void set(Uri key, Response response) {
    _cache[key] = CacheObject(response, Helper.timestamp());
  }

  /// ✅ 移除缓存
  void remove(Uri key) => _cache.remove(key);

  /// ✅ 清除所有缓存
  void clearAll() => _cache.clear();

  /// ✅ 精准清除（完整 URI 字符串）
  void clearByKey(String key) => _cache.remove(Uri.tryParse(key));

  /// ✅ 按路径清除，如 /api/user/info
  void clearByPath(String path) {
    _cache.removeWhere((uri, _) => uri.path == path);
  }

  /// ✅ 批量清除多个路径
  void clearMultipleByPaths(List<String> paths) {
    _cache.removeWhere((uri, _) => paths.contains(uri.path));
  }

  /// ✅ 可选：基于前缀模糊清除，如 `/api/user/` 开头的
  void clearByPrefix(String prefix) {
    _cache.removeWhere((uri, _) => uri.path.startsWith(prefix));
  }
}
