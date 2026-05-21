/// Interceptor that attaches the JWT bearer token and handles 401 responses.
library;

import 'package:dio/dio.dart';

import '../constants/hive_keys.dart';
import '../storage/hive_service.dart';

/// Dio interceptor responsible for:
///
///  - Attaching the JWT bearer token to every outbound request, when present.
///  - On a 401 response, clearing the cached session so the router redirects
///    back to onboarding/login on the next navigation tick.
///
/// Refresh-token rotation is intentionally NOT implemented in Phase 1 - the
/// backend's refresh contract has not been finalised. To be added in a later
/// phase via a fresh decision record.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._hiveService);

  final HiveService _hiveService;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _hiveService.authBox.get(HiveKeys.keyJwtToken) as String?;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      // TODO(refresh-token): call refresh endpoint and replay the original request
      //   once the backend refresh contract is finalised.
      _hiveService.authBox.delete(HiveKeys.keyJwtToken);
      _hiveService.authBox.delete(HiveKeys.keyCurrentUser);
    }
    handler.next(err);
  }
}
