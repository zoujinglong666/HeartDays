import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:heart_days/Consts/index.dart';
import 'package:heart_days/common/helper.dart';

final class CacheInterceptor extends Interceptor {
  bool isCaching = false;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.method != "GET") {
      return super.onRequest(options, handler);
    }
    isCaching = false;

    final cacheKey = options.uri;
    final cache = CacheManager.observer;
    if (cache.contains(cacheKey)) {
      print("命中缓存 -> $cacheKey");
      final cacheObject = cache.getValue(cacheKey);
      final current = Helper.timestamp();
      final cacheTime = Consts.request.cachedTime.inMilliseconds;
      if (current - cacheObject.timestamp > cacheTime) {
        print("缓存超时，自动清理 -> $cacheKey");
        cache.clear(cacheKey);
        return super.onRequest(options, handler);
      }
      return handler.resolve(cacheObject.data);
    }

    isCaching = true;
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (isCaching) {
      final cache = CacheManager.observer;
      final options = response.requestOptions;
      final cacheKey = options.uri;
      print("设置缓存 -> $cacheKey");
      cache.setValue(cacheKey, response);
    }
    super.onResponse(response, handler);
  }
}

class CacheObject {
  final Response data;
  final int timestamp;

  const CacheObject(this.data, this.timestamp);
}

class CacheManager extends RouteObserver<Route<dynamic>> {
  CacheManager._();

  static final CacheManager observer = CacheManager._();

  final cached = <Uri, CacheObject>{};

  bool contains(Uri key) => cached.containsKey(key);

  CacheObject getValue(Uri key) => cached[key]!;

  void setValue(Uri key, Response data) =>
      cached[key] = CacheObject(data, Helper.timestamp());

  void clear(Uri key) => cached.remove(key);


  // ✅ 新增：根据 Uri 清理缓存
  void clearByUri(Uri uri) {
    cached.removeWhere((key, value) => key == uri);
  }

  // ✅ 新增：根据路径清除缓存（如 /api/list）
  void clearByPath(String path) {
    cached.removeWhere((key, value) => key.path == path);
  }

  // ✅ 新增：清除多个路径的缓存
  void clearMultipleByPath(List<String> paths) {
    cached.removeWhere((key, value) => paths.contains(key.path));
  }

  // ✅ 新增：根据完整 key 字符串清除缓存（用于精准清除）
  void clearByKey(String key) {
    cached.remove(Uri.tryParse(key));
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    cached.clear();
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    cached.clear();
  }
}