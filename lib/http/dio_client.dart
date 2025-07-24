import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:heart_days/Consts/index.dart';
import 'package:heart_days/http/interceptors/cache_interceptor.dart';
import 'package:http_cache_hive_store/http_cache_hive_store.dart';
import 'dart:io';

import 'interceptors/log_interceptor.dart';
import 'interceptors/loading_interceptor.dart';
import 'interceptors/token_interceptor.dart';
import 'interceptors/adapter_interceptor.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:path_provider/path_provider.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();

  factory DioClient() => _instance;

  late final Dio dio;

  DioClient._internal() {
    BaseOptions options = BaseOptions(
      baseUrl: Consts.request.baseUrl,
      connectTimeout: Consts.request.connectTimeout,
      receiveTimeout: Consts.request.receiveTimeout,
      headers: {'Accept': 'application/json', 'version': '1.0.0'},
    );

    dio = Dio(options);
    // 配置缓存拦截器
    _setupCacheInterceptor();

    /// 在不同环境下加载不同的请求基础路径
    void changeBaseUrl(String url) => dio.options.baseUrl = url;

    /// 重置基础路径
    void resetBaseUrl() => changeBaseUrl(Consts.request.baseUrl);
    dio.interceptors.addAll([
      AdapterInterceptorHandler(),
      LogInterceptorHandler(),
      LoadingInterceptorHandler(),
      TokenInterceptorHandler(dio),
    ]);

    dio.httpClientAdapter =
        DefaultHttpClientAdapter()
          ..onHttpClientCreate = (client) {
            client.findProxy = (uri) => "DIRECT";
            client.badCertificateCallback =
                (X509Certificate cert, String host, int port) => true;
            return client;
          };
  }

  void _setupCacheInterceptor() async {
    // 缓存配置
    final dir = await getTemporaryDirectory();
    final cacheOptions = CacheOptions(
      store: HiveCacheStore(dir.path),
      policy: CachePolicy.request, // 可设为 CachePolicy.forceCache 等
      priority: CachePriority.normal,
      maxStale: const Duration(days: 7),
    );

    dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));
  }
}
