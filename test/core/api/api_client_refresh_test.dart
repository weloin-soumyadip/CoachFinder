/// Tests the ApiClient's 401 → refresh → retry interceptor, including the
/// single-flight guard, using a hand-rolled fake Dio adapter + in-memory token
/// storage (no mocking package is in the stack).
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:coachfinder/core/api/api_client.dart';
import 'package:coachfinder/core/api/api_config.dart';
import 'package:coachfinder/core/storage/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [TokenStorage] — avoids `flutter_secure_storage` in unit tests.
class _FakeTokenStorage implements TokenStorage {
  _FakeTokenStorage({String? access, String? refresh})
      : _access = access,
        _refresh = refresh;

  String? _access;
  String? _refresh;

  int clearCount = 0;

  @override
  Future<String?> getAccessToken() async => _access;

  @override
  Future<String?> getRefreshToken() async => _refresh;

  @override
  Future<void> saveAccessToken(String token) async => _access = token;

  @override
  Future<void> saveRefreshToken(String token) async => _refresh = token;

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
  }) async {
    _access = accessToken;
    if (refreshToken != null) _refresh = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    clearCount++;
    _access = null;
    _refresh = null;
  }

  @override
  Future<bool> isTokenValid() async => _access != null && _access!.isNotEmpty;

  @override
  Future<bool> hasToken() async => _access != null;
}

/// Fake adapter: a protected endpoint that 401s unless the Authorization header
/// carries [validAccess], and a `/auth/refresh` that rotates the token when the
/// expected refresh token is present in the request body.
class _FakeAdapter implements HttpClientAdapter {
  int refreshCalls = 0;
  int protectedCalls = 0;
  String validAccess = 'fresh-access';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.contains(ApiConfig.authRefresh)) {
      refreshCalls++;
      // The refresh token is sent in the JSON request body.
      String body = '';
      if (requestStream != null) {
        final List<int> bytes =
            (await requestStream.toList()).expand((c) => c).toList();
        body = utf8.decode(bytes);
      }
      if (body.contains('refresh-1')) {
        return _json(<String, dynamic>{
          'success': true,
          'accessToken': validAccess,
          'refreshToken': 'refresh-2',
        }, 200);
      }
      return _json(<String, dynamic>{'success': false}, 401);
    }

    // Protected endpoint.
    protectedCalls++;
    final String? auth = options.headers['Authorization'] as String?;
    if (auth == 'Bearer $validAccess') {
      return _json(<String, dynamic>{'success': true}, 200);
    }
    return _json(
        <String, dynamic>{'success': false, 'message': 'expired'}, 401);
  }

  ResponseBody _json(Map<String, dynamic> body, int status) =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

/// Builds an unsigned JWT whose `exp` is [secondsFromNow] from now — enough for
/// the client's `exp`-decode (it never verifies the signature).
String _jwtExpiring(int secondsFromNow) {
  final int exp = DateTime.now()
          .toUtc()
          .add(Duration(seconds: secondsFromNow))
          .millisecondsSinceEpoch ~/
      1000;
  String seg(Map<String, dynamic> m) =>
      base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
  return '${seg(<String, dynamic>{'alg': 'HS256', 'typ': 'JWT'})}.'
      '${seg(<String, dynamic>{'exp': exp})}.sig';
}

ApiClient _buildClient(_FakeTokenStorage storage, _FakeAdapter adapter) {
  final Dio dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl))
    ..httpClientAdapter = adapter;
  final Dio refreshDio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl))
    ..httpClientAdapter = adapter;
  return ApiClient(tokenStorage: storage, dio: dio, refreshDio: refreshDio);
}

void main() {
  test('a 401 refreshes the token and transparently retries the request',
      () async {
    final storage =
        _FakeTokenStorage(access: 'expired-access', refresh: 'refresh-1');
    final adapter = _FakeAdapter();
    final client = _buildClient(storage, adapter);

    final response = await client.get<void>('/protected');

    expect(response.success, true);
    expect(adapter.refreshCalls, 1);
    // First attempt 401s, retry after refresh succeeds.
    expect(adapter.protectedCalls, 2);
    // Rotated tokens were persisted.
    expect(await storage.getAccessToken(), 'fresh-access');
    expect(await storage.getRefreshToken(), 'refresh-2');
    expect(storage.clearCount, 0);
  });

  test('an expired access token is refreshed proactively, before the request',
      () async {
    // Stored access token is a real (unsigned) JWT that already expired.
    final storage = _FakeTokenStorage(
      access: _jwtExpiring(-60),
      refresh: 'refresh-1',
    );
    final adapter = _FakeAdapter();
    final client = _buildClient(storage, adapter);

    final response = await client.get<void>('/protected');

    expect(response.success, true);
    expect(adapter.refreshCalls, 1);
    // No 401 round-trip: the protected endpoint is hit once, already with the
    // refreshed token.
    expect(adapter.protectedCalls, 1);
    expect(await storage.getAccessToken(), 'fresh-access');
  });

  test('a still-valid access token is not refreshed proactively', () async {
    final storage = _FakeTokenStorage(
      access: _jwtExpiring(600),
      refresh: 'refresh-1',
    );
    final adapter = _FakeAdapter()..validAccess = _jwtExpiring(600);
    // The protected endpoint accepts the (valid) stored token as-is.
    final client = ApiClient(
      tokenStorage: storage,
      dio: Dio(BaseOptions(baseUrl: ApiConfig.baseUrl))
        ..httpClientAdapter = adapter,
      refreshDio: Dio(BaseOptions(baseUrl: ApiConfig.baseUrl))
        ..httpClientAdapter = adapter,
    );
    adapter.validAccess = await storage.getAccessToken() ?? '';

    final response = await client.get<void>('/protected');

    expect(response.success, true);
    expect(adapter.refreshCalls, 0);
    expect(adapter.protectedCalls, 1);
  });

  test('concurrent 401s trigger exactly one refresh (single-flight)', () async {
    final storage =
        _FakeTokenStorage(access: 'expired-access', refresh: 'refresh-1');
    final adapter = _FakeAdapter();
    final client = _buildClient(storage, adapter);

    final results = await Future.wait(<Future<dynamic>>[
      client.get<void>('/protected'),
      client.get<void>('/protected'),
      client.get<void>('/protected'),
    ]);

    expect(results.every((r) => r.success == true), true);
    expect(adapter.refreshCalls, 1);
    expect(storage.clearCount, 0);
  });
}
