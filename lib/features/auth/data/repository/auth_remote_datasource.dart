/// Dio calls for login, register, and refresh endpoints.
library;

import 'package:dio/dio.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/error/app_exception.dart';
import '../models/auth_response_model.dart';
import '../models/register_request_model.dart';

/// Contract for the backend-talking layer of the auth feature. Implementations
/// throw [AppException] subclasses; the repository catches and maps to
/// [AppFailure].
abstract interface class AuthRemoteDataSource {
  /// Calls `POST /api/auth/register`. Returns the parsed [AuthResponse] on
  /// 201; throws [ServerException] on a 4xx/5xx response or
  /// [NetworkException] on connectivity / timeout.
  Future<AuthResponse> register(RegisterRequest request);
}

/// Dio-backed implementation.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  /// Wraps the provided [Dio] instance — typically the singleton from
  /// `dioProvider`.
  AuthRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<AuthResponse> register(RegisterRequest request) async {
    try {
      final Response<Map<String, dynamic>> response =
          await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.authRegister,
        data: request.toJson(),
      );
      final Map<String, dynamic>? body = response.data;
      if (body == null) {
        throw const ServerException('Empty response from server');
      }
      return AuthResponse.fromJson(body);
    } on DioException catch (e) {
      throw _mapDioException(e);
    } on FormatException catch (e) {
      throw ServerException('Unexpected response shape', cause: e);
    } on TypeError catch (e) {
      throw ServerException('Unexpected response shape', cause: e);
    }
  }
}

/// Translates a [DioException] into the project's [AppException] hierarchy.
///
/// - Connection / timeout / DNS → [NetworkException].
/// - 4xx with a `{message: ...}` body → [ServerException] carrying that
///   message verbatim (the backend's messages are user-actionable).
/// - 5xx → [ServerException] with a generic message (we don't surface raw
///   500s to users — they may leak internals).
/// - Anything else → [ServerException] with a generic message.
AppException _mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return NetworkException(
        'No connection. Check your internet and try again.',
        cause: e,
      );
    case DioExceptionType.badCertificate:
    case DioExceptionType.cancel:
    case DioExceptionType.unknown:
    case DioExceptionType.badResponse:
      final int? status = e.response?.statusCode;
      if (status != null && status >= 400 && status < 500) {
        final String message = (e.response?.data is Map<String, dynamic> &&
                (e.response!.data as Map<String, dynamic>)['message'] is String)
            ? (e.response!.data as Map<String, dynamic>)['message'] as String
            : 'Request failed';
        return ServerException(message, statusCode: status, cause: e);
      }
      if (status != null && status >= 500) {
        return ServerException(
          'Something went wrong, please try again.',
          statusCode: status,
          cause: e,
        );
      }
      return ServerException('Unexpected error', cause: e);
  }
}
