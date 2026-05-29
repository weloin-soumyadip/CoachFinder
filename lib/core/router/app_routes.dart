/// Named route constants used by GoRouter and call sites.
library;

import '../providers/role_provider.dart';

/// Named route identifiers. All `context.goNamed(...)` / `pushNamed(...)` calls
/// must use one of these constants - never raw strings.
abstract final class AppRoutes {
  AppRoutes._();

  // Entry / auth
  static const String onboarding = 'onboarding';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgot-password';

  // Student
  static const String studentHome = 'student-home';
  static const String studentSearch = 'student-search';
  static const String studentFilter = 'student-filter';
  static const String studentCenterDetail = 'student-center-detail';
  static const String studentProfile = 'student-profile';
  static const String studentSaved = 'student-saved';

  // Owner
  static const String ownerDashboard = 'owner-dashboard';
  static const String ownerManageCenter = 'owner-manage-center';
  static const String ownerCreateCenter = 'owner-create-center';
  static const String ownerEditCenter = 'owner-edit-center';
  static const String ownerEnquiryInbox = 'owner-enquiry-inbox';
  static const String ownerEnquiryDetail = 'owner-enquiry-detail';
  static const String ownerProfile = 'owner-profile';

  // Teacher
  static const String teacherHome = 'teacher-home';
  static const String teacherSearch = 'teacher-search';
  static const String teacherEnquiries = 'teacher-enquiries';
  static const String teacherSchedule = 'teacher-schedule';
  static const String teacherProfile = 'teacher-profile';
  static const String teacherEditProfile = 'teacher-edit-profile';
}

/// The shell-home route NAME a freshly-authenticated [role] should land on.
///
/// Single source of truth shared by the login and register flows so the two
/// stay in sync. The router's own redirect guard maps the same roles to their
/// path equivalents.
String landingRouteForRole(String role) {
  if (role == roleOwner) return AppRoutes.ownerDashboard;
  if (role == roleTeacher) return AppRoutes.teacherHome;
  return AppRoutes.studentHome; // student (default)
}
