/// Dio wrapper handling auth-header injection and structured error mapping.
library;

import 'package:dio/dio.dart';

import '../storage/local_storage.dart';
import '../storage/token_storage.dart';
import 'api_config.dart';
import 'api_error.dart';
import 'api_response.dart';

/// The single HTTP entry point repositories use. Wraps Dio with:
///   - an interceptor that injects `Authorization: Bearer <accessToken>` on
///     every outbound request when [TokenStorage] has one;
///   - a 401 handler that clears both [TokenStorage] and the cached
///     `currentUserId` in [LocalStorage] so the router's session check
///     falls back to the login screen on the next navigation tick
///     (refresh-token rotation is a later round);
///   - error mapping from [DioException] into the structured [ApiError]
///     types — timeouts, network failures, 4xx with backend `message`, and
///     a generic 5xx.
///
/// Inject a [TokenStorage] (or a [Dio]) for tests; the defaults are fine in
/// app code.
class ApiClient {
  ApiClient({TokenStorage? tokenStorage, Dio? dio})
      : _tokenStorage = tokenStorage ?? TokenStorage() {
    _dio = dio ?? _createDio();
    _setupInterceptors();
  }

  late final Dio _dio;
  final TokenStorage _tokenStorage;

  Dio _createDio() {
    return Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectionTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _tokenStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            await _tokenStorage.clearTokens();
            await LocalStorage.remove(StorageKeys.currentUserId);
          }
          handler.next(e);
        },
      ),
    );
  }

  /// Issues `POST [path]` with [data] as the body, parses the response into
  /// [ApiResponse<T>] using [fromJson] when provided. Throws [ApiError] on
  /// HTTP / network failure.
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.post<Map<String, dynamic>>(path, data: data);
      return ApiResponse<T>.fromJson(
        response.data ?? <String, dynamic>{},
        fromJson,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Issues `GET [path]`, parses the response into [ApiResponse<T>] using
  /// [fromJson] when provided. Throws [ApiError] on HTTP / network failure.
  Future<ApiResponse<T>> get<T>(
    String path, {
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.get<Map<String, dynamic>>(path);
      return ApiResponse<T>.fromJson(
        response.data ?? <String, dynamic>{},
        fromJson,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Issues `POST [path]` with [data] and returns the raw [Response] so
  /// callers can wrap with [ApiResponse.fromJson] using a custom payload
  /// extractor. Used by the auth repository, where the envelope shape is
  /// non-standard (`{success, accessToken, refreshToken, user}` at the top
  /// level rather than under `data`).
  Future<Response<Map<String, dynamic>>> rawPost(
    String path, {
    dynamic data,
  }) async {
    try {
      return await _dio.post<Map<String, dynamic>>(path, data: data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  ApiError _mapDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiError.timeout();
      case DioExceptionType.connectionError:
        return ApiError.network();
      case DioExceptionType.badResponse:
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        final int? status = e.response?.statusCode;
        final dynamic body = e.response?.data;
        if (body is Map<String, dynamic>) {
          return ApiError.fromJson(body, statusCode: status);
        }
        if (status != null && status >= 500) {
          return ApiError(
            statusCode: status,
            message: 'Something went wrong, please try again.',
          );
        }
        return ApiError.unknown();
    }
  }
}
