import 'package:dio/dio.dart';
import 'package:heart_days/Consts/index.dart';
import 'package:heart_days/provider/auth_provider.dart'; // 添加导入
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 添加导入
import 'interceptors/log_interceptor.dart';
import 'interceptors/loading_interceptor.dart';
import 'interceptors/token_interceptor.dart';
import 'interceptors/adapter_interceptor.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();

  factory DioClient() => _instance;

  late final Dio dio;
  static final ProviderContainer _container = ProviderContainer(); // 添加 ProviderContainer

  DioClient._internal() {
    BaseOptions options = BaseOptions(
      baseUrl: Consts.request.baseUrl,
      connectTimeout: Consts.request.connectTimeout,
      receiveTimeout: Consts.request.receiveTimeout,
      headers: {'Accept': 'application/json', 'version': '1.0.0'},
    );

    dio = Dio(options);
    // 配置缓存拦截器
    // _setupCacheInterceptor();

    /// 在不同环境下加载不同的请求基础路径
    void changeBaseUrl(String url) => dio.options.baseUrl = url;

    /// 重置基础路径
    void resetBaseUrl() => changeBaseUrl(Consts.request.baseUrl);

    // 获取 AuthNotifier 实例
    final authNotifier = _container.read(authProvider.notifier);

    dio.interceptors.addAll([
      AdapterInterceptorHandler(),
      LogInterceptorHandler(),
      LoadingInterceptorHandler(),
      TokenInterceptorHandler(dio, authNotifier), // 传递 authNotifier
    ]);
  }

  // void _setupCacheInterceptor() async {
  //   // 缓存配置
  //   final dir = await getTemporaryDirectory();
  //   final cacheOptions = CacheOptions(
  //     store: HiveCacheStore(dir.path),
  //     policy: CachePolicy.request, // 可设为 CachePolicy.forceCache 等
  //     priority: CachePriority.normal,
  //     maxStale: const Duration(days: 7),
  //   );
  //
  //   dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));
  // }
}
