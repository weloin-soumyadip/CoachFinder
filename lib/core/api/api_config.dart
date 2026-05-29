/// HTTP base URL, timeouts, and backend endpoint path constants.
library;

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// Backend connection configuration. Single source of truth for the base URL
/// the [ApiClient] dials and the path constants every repository quotes.
class ApiConfig {
  ApiConfig._();

  /// Local dev backend port. Mirrors `PORT=5000` in `server/.env`.
  static const int _devPort = 5000;

  /// Base URL for the local dev backend. Selected per platform because
  /// `localhost` from inside the Android emulator points back at the emulator
  /// itself, not the host — the emulator exposes the host as `10.0.2.2`.
  ///
  /// - **Web / desktop / iOS simulator** → `http://localhost:5000/api`
  /// - **Android emulator** → `http://10.0.2.2:5000/api`
  ///
  /// Physical devices need a LAN IP — out of scope here; override with a
  /// `--dart-define=BACKEND_BASE_URL=…` when you get there.
  static final String baseUrl = _resolveBaseUrl();

  static String _resolveBaseUrl() {
    const String override = String.fromEnvironment('BACKEND_BASE_URL');
    if (override.isNotEmpty) return override;
    if (kIsWeb) return 'http://localhost:$_devPort/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:$_devPort/api';
    }
    return 'http://localhost:$_devPort/api';
  }

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
