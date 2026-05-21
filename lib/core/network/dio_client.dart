/// Configured Dio instance with BaseOptions and interceptors attached.
library;

import 'package:dio/dio.dart';

import '../constants/api_endpoints.dart';
import 'auth_interceptor.dart';

/// Builds the application's [Dio] instance. Called from `dioProvider`.
abstract final class DioClient {
  DioClient._();

  /// Construct a configured [Dio] instance with the given interceptor attached.
  static Dio build({required AuthInterceptor authInterceptor}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        responseType: ResponseType.json,
      ),
    );

    dio.interceptors.add(authInterceptor);
    return dio;
  }
}
