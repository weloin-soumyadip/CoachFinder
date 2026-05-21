/// Named route constants used by GoRouter and call sites.
library;

/// Named route identifiers. All `context.goNamed(...)` / `pushNamed(...)` calls
/// must use one of these constants - never raw strings.
abstract final class AppRoutes {
  AppRoutes._();

  // Entry / auth
  static const String onboarding = 'onboarding';
  static const String login = 'login';
  static const String register = 'register';

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
  static const String ownerEnquiryInbox = 'owner-enquiry-inbox';
  static const String ownerEnquiryDetail = 'owner-enquiry-detail';
}
