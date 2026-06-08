/// HTTP base URL, timeouts, and backend endpoint path constants.
library;

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

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
  /// - **Android (this project's physical device on the LAN)** → the laptop's
  ///   current LAN IP, [_androidDevHost] (the backend's Docker port is published
  ///   on `0.0.0.0:5000`, so a device on the same Wi-Fi can reach it).
  ///
  /// **The LAN IP is DHCP-assigned and changes** — if a physical Android build
  /// suddenly shows "No connection", the laptop's IP has almost certainly moved;
  /// update [_androidDevHost] (run `hostname -I`) or, better, pass the address
  /// at launch without editing code:
  ///   `flutter run --dart-define=BACKEND_BASE_URL=http://<laptop-ip>:5000/api`
  /// The `--dart-define` override always wins. On the **emulator**, override with
  /// `http://10.0.2.2:5000/api` (the LAN IP below is for a real device).
  static final String baseUrl = _resolveBaseUrl();

  /// Laptop's current LAN IP for physical-Android dev builds. DHCP-assigned —
  /// re-check with `hostname -I` if a device build can't reach the backend.
  static const String _androidDevHost = '192.168.1.37';

  static String _resolveBaseUrl() {
    const String override = String.fromEnvironment('BACKEND_BASE_URL');
    if (override.isNotEmpty) return override;
    if (kIsWeb) return 'http://localhost:$_devPort/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://$_androidDevHost:$_devPort/api';
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

  // Student endpoint paths.
  static const String studentsDashboard = '/students/dashboard';

  /// Owner dashboard: `GET /api/owners/dashboard` (owner role). Returns the
  /// `{success, data:{…}}` envelope with the owner's center metrics.
  static const String ownersDashboard = '/owners/dashboard';

  /// Owner self profile: `PATCH /api/owners/me` (strict partial update,
  /// replies `{user: <doc>}`). Read/prefill uses [authMe].
  static const String ownersMe = '/owners/me';

  /// Owner password change: `POST /api/owners/me/password`
  /// (body `{currentPassword, newPassword}`; replies re-issued tokens).
  static const String ownersMePassword = '/owners/me/password';

  /// Owner enquiries list: `GET /api/owners/enquiries` (query `page,limit,status?`)
  /// → `{success, data:[…], pagination}` scoped to the owner's centre.
  static const String ownersEnquiries = '/owners/enquiries';

  /// Owner enquiries search: `GET /api/owners/enquiries/search`
  /// (query `page,limit,q?,status?,subject?,student?,dateFrom?,dateTo?`).
  static const String ownersEnquiriesSearch = '/owners/enquiries/search';

  /// A single owner enquiry: `GET`/`PATCH /api/owners/enquiries/:id`
  /// (`{enquiry}`; PATCH body `{status?, ownerNotes?}`).
  static String ownerEnquiryById(String id) => '/owners/enquiries/$id';

  /// Coaching centers: `POST /api/centers` (owner role) creates the owner's
  /// single center; replies `201 {center: <doc>}` at the top level (409 if the
  /// owner already has one). Also the public `GET /api/centers` list.
  static const String centers = '/centers';

  /// Owner's own center: `GET /api/centers/me` (owner role) → `{center: <doc>}`
  /// or `404` when the owner has not created one yet.
  static const String centersMe = '/centers/me';

  /// Owner center update: `PATCH /api/centers/:id` (owner role, strict partial)
  /// → `{center: <updated doc>}`. Also the public `GET /api/centers/:id`
  /// (student detail). Build the path with [centerById].
  static String centerById(String id) => '/centers/$id';

  /// Public center reviews: `GET /api/centers/:id/reviews` (paginated) and the
  /// student-authored `POST` to the same path.
  static String centerReviews(String id) => '/centers/$id/reviews';

  /// Record a center profile view: `POST /api/centers/:id/views`
  /// (student/teacher; fire-and-forget analytics).
  static String centerViews(String id) => '/centers/$id/views';

  /// Student-authored enquiry to a center: `POST /api/centers/:id/enquiries`
  /// (body `{message, subject?}`).
  static String centerEnquiries(String id) => '/centers/$id/enquiries';

  /// Public subjects list: `GET /api/subjects` → `{data:[{_id,name,slug}], …}`.
  /// Backs the centre subject multi-select.
  static const String subjects = '/subjects';

  /// Student bookmarks: `GET`/`POST /api/students/bookmarks`,
  /// `DELETE /api/students/bookmarks/:id`.
  static const String studentsBookmarks = '/students/bookmarks';

  /// Student self profile: `PATCH /api/students/me` (strict partial update,
  /// replies `{user: <doc>}`). Read/prefill uses [authMe].
  static const String studentsMe = '/students/me';

  /// Student password change: `POST /api/students/me/password`
  /// (body `{currentPassword, newPassword}`).
  static const String studentsMePassword = '/students/me/password';

  /// Public teacher profile: `GET /api/teachers/:id` → `{teacher: <doc>}`.
  static String teacherById(String id) => '/teachers/$id';

  /// Public teacher reviews: `GET /api/teachers/:id/reviews` (paginated).
  static String teacherReviews(String id) => '/teachers/$id/reviews';

  /// Unified search endpoint: `GET /api/search?searchType=teacher|coaching|webinar`.
  static const String search = '/search';
}
