/// HTTP base URL, timeouts, and backend endpoint path constants.
library;

/// Backend connection configuration. Single source of truth for the base URL
/// the [ApiClient] dials and the path constants every repository quotes.
class ApiConfig {
  ApiConfig._();

  /// Base URL for the local dev backend (Android emulator host loopback).
  /// iOS simulator + physical-device URL switching is out of scope per ADR 0002.
  static const String baseUrl = 'http://10.0.2.2:5000/api';

  /// Dio connection timeout.
  static const Duration connectionTimeout = Duration(seconds: 15);

  /// Dio receive timeout.
  static const Duration receiveTimeout = Duration(seconds: 15);

  // Auth endpoint paths (added as the corresponding features wire up).
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';
  static const String authMe = '/auth/me';
}
