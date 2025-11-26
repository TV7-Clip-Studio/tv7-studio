import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:forgotten_client/config/app_config.dart';
import 'package:forgotten_client/data/auth/token_store.dart';

class ApiClient {
  ApiClient({required this.config, required this.tokenStore})
    : dio =
          Dio(
              BaseOptions(
                baseUrl: config.apiBaseUrl.toString(),
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 30),
              ),
            )
            ..interceptors.add(_AuthInterceptor(tokenStore: tokenStore))
            ..interceptors.add(
              LogInterceptor(
                requestBody: true,
                responseBody: true,
                logPrint: (msg) => debugPrint('[api] $msg'),
              ),
            );

  final AppConfig config;
  final TokenStore tokenStore;
  final Dio dio;

  void close() {
    dio.close(force: true);
  }
}

class _AuthInterceptor extends Interceptor {
  _AuthInterceptor({required this.tokenStore});

  final TokenStore tokenStore;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final tokens = await tokenStore.read();
    if (tokens != null && tokens.accessToken.isNotEmpty) {
      options.headers.putIfAbsent(
        'Authorization',
        () => 'Bearer ${tokens.accessToken}',
      );
    }
    super.onRequest(options, handler);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final status = err.response?.statusCode;
    if (status == 401) {
      // TODO(tv7): hook token refresh with AuthRepository once available.
    }
    super.onError(err, handler);
  }
}
