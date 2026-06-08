/// Dio wrapper handling auth-header injection and structured error mapping.
library;

import 'dart:convert';

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
  ApiClient({TokenStorage? tokenStorage, Dio? dio, Dio? refreshDio})
      : _tokenStorage = tokenStorage ?? TokenStorage() {
    _dio = dio ?? _createDio();
    // A second, interceptor-free Dio dedicated to the `/auth/refresh` call so a
    // 401 there can never re-enter the refresh flow and loop.
    _refreshDio = refreshDio ?? _createDio();
    _setupInterceptors();
  }

  late final Dio _dio;
  late final Dio _refreshDio;
  final TokenStorage _tokenStorage;

  /// In-flight refresh, shared by every request that 401s concurrently so the
  /// backend's refresh-token rotation runs exactly once per expiry. Resolves to
  /// the new access token, or null when refresh is impossible / fails.
  Future<String?>? _refreshFuture;

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

  /// Marks a [RequestOptions] as already having been retried after a refresh,
  /// so a second 401 falls through to logout instead of looping.
  static const String _retriedFlag = '__retried_after_refresh';

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          String? token = await _tokenStorage.getAccessToken();
          // Proactive refresh: if the stored access token is already expired
          // (or within the skew window), rotate it BEFORE sending rather than
          // waiting for the server to 401. The reactive handler below remains
          // as a safety net for clock skew / server-side revocation.
          if (token != null &&
              token.isNotEmpty &&
              _isAccessTokenExpired(token)) {
            final String? refreshed = await _refreshAccessToken();
            if (refreshed != null) token = refreshed;
          }
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException e, handler) async {
          final RequestOptions options = e.requestOptions;
          final bool isAuthFailure = e.response?.statusCode == 401;
          final bool isRefreshCall =
              options.path.contains(ApiConfig.authRefresh);
          final bool alreadyRetried = options.extra[_retriedFlag] == true;

          // Only attempt a refresh+retry once, and never for the refresh call
          // itself (that would recurse).
          if (isAuthFailure && !isRefreshCall && !alreadyRetried) {
            final String? newToken = await _refreshAccessToken();
            if (newToken != null) {
              try {
                final Response<dynamic> retried =
                    await _retryWithToken(options, newToken);
                return handler.resolve(retried);
              } on DioException catch (retryError) {
                return handler.next(retryError);
              }
            }
            // Refresh impossible or failed — drop the session so the router
            // bounces to login on the next navigation tick.
            await _clearSession();
            return handler.next(e);
          }

          // A 401 on the refresh call (or on an already-retried request) means
          // the refresh token is gone/expired too: end the session.
          if (isAuthFailure && (isRefreshCall || alreadyRetried)) {
            await _clearSession();
          }
          handler.next(e);
        },
      ),
    );
  }

  /// Seconds of clock-skew slack: treat the token as expired this long before
  /// its real `exp` so we refresh just ahead of the server rejecting it.
  static const int _expirySkewSeconds = 15;

  /// Decodes a JWT's `exp` claim (no signature check — that's the server's job)
  /// and reports whether it is at/past expiry within [_expirySkewSeconds].
  /// Returns false when the token can't be parsed, leaving the reactive 401
  /// path to handle it.
  bool _isAccessTokenExpired(String jwt) {
    try {
      final List<String> parts = jwt.split('.');
      if (parts.length != 3) return false;
      final Map<String, dynamic> payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      final dynamic exp = payload['exp'];
      if (exp is! int) return false;
      final DateTime expiry =
          DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
      return DateTime.now().toUtc().isAfter(
            expiry.subtract(const Duration(seconds: _expirySkewSeconds)),
          );
    } catch (_) {
      return false;
    }
  }

  /// Returns a refreshed access token, or null when refresh is impossible
  /// (no stored refresh token) or the backend rejected it. Single-flight: all
  /// concurrent callers await the same in-flight refresh.
  Future<String?> _refreshAccessToken() {
    return _refreshFuture ??=
        _performRefresh().whenComplete(() => _refreshFuture = null);
  }

  /// Calls `POST /auth/refresh` on the interceptor-free [_refreshDio] and
  /// persists the rotated tokens. Returns the new access token, or null on any
  /// failure.
  ///
  /// The refresh token is sent in the request **body** (the backend accepts it
  /// there as well as from the HttpOnly cookie). This works identically on web
  /// and mobile — a browser SPA on a different origin can't reliably persist or
  /// send the cookie (SameSite + no Secure over http), and JS can't set the
  /// `Cookie` header — so the body is the portable channel.
  Future<String?> _performRefresh() async {
    final String? refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;
    try {
      final Response<Map<String, dynamic>> response =
          await _refreshDio.post<Map<String, dynamic>>(
        ApiConfig.authRefresh,
        data: <String, dynamic>{'refreshToken': refreshToken},
      );
      final Map<String, dynamic> body = response.data ?? <String, dynamic>{};
      final String? newAccess = body['accessToken'] as String?;
      final String? newRefresh = body['refreshToken'] as String?;
      if (newAccess == null || newAccess.isEmpty) return null;
      await _tokenStorage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
      return newAccess;
    } on DioException {
      return null;
    }
  }

  /// Re-issues the original [options] with the refreshed [token] and the
  /// retry guard set, so a fresh 401 won't loop.
  Future<Response<dynamic>> _retryWithToken(
    RequestOptions options,
    String token,
  ) {
    options.headers['Authorization'] = 'Bearer $token';
    options.extra[_retriedFlag] = true;
    return _dio.fetch<dynamic>(options);
  }

  /// Wipes the stored tokens + cached user id so the router falls back to the
  /// login screen on the next navigation tick.
  Future<void> _clearSession() async {
    await _tokenStorage.clearTokens();
    await LocalStorage.remove(StorageKeys.currentUserId);
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

  /// Issues `GET [path]` with optional [queryParameters], parses the response
  /// into [ApiResponse<T>] using [fromJson] when provided. Throws [ApiError]
  /// on HTTP / network failure.
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
      return ApiResponse<T>.fromJson(
        response.data ?? <String, dynamic>{},
        fromJson,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Issues `GET [path]` with optional [queryParameters] and returns the raw
  /// [Response] so callers can read envelope siblings that [ApiResponse] drops
  /// — notably the `pagination` block beside `data` on the paginated list /
  /// search endpoints. Mirrors [rawPost]. Throws [ApiError] on failure.
  Future<Response<Map<String, dynamic>>> rawGet(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParameters,
      );
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  /// Issues `DELETE [path]`. Returns the raw [Response]; callers ignore the
  /// body and rely on the absence of a thrown [ApiError]. Goes through the same
  /// interceptor as every other verb, so auth-header injection + token refresh
  /// apply. Throws [ApiError] on HTTP / network failure.
  ///
  /// [ResponseType.plain] is used defensively for ALL deletes: it returns the
  /// body unparsed, so an empty `204 No Content` reply can never break Flutter
  /// **web** (where Dio's default JSON type runs `jsonDecode('')` on the empty
  /// body and throws — the original bookmark "remove" bug). The backend now
  /// replies `200 {success, message}` on a bookmark delete, but other/future
  /// delete endpoints may still 204, so keeping `plain` here is the safe default.
  Future<Response<dynamic>> delete(String path) async {
    try {
      return await _dio.delete<dynamic>(
        path,
        options: Options(responseType: ResponseType.plain),
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

  /// Issues `PATCH [path]` with [data] and returns the raw [Response] so
  /// callers can read envelope siblings the standard [ApiResponse] drops — the
  /// student profile update replies `{user: <doc>}` at the top level rather than
  /// nesting under `data`. Mirrors [rawPost]; goes through the same interceptor
  /// (auth-header injection + token refresh apply). Throws [ApiError] on
  /// HTTP / network failure.
  Future<Response<Map<String, dynamic>>> rawPatch(
    String path, {
    dynamic data,
  }) async {
    try {
      return await _dio.patch<Map<String, dynamic>>(path, data: data);
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
