/// GoRouter configuration with student and owner shells and redirect guards.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/layouts/adaptive_navigation.dart';
import '../constants/app_strings.dart';
import '../providers/role_provider.dart';
import '../storage/local_storage.dart';
import 'app_routes.dart';

// Feature screens. These are placeholder Scaffolds at this point and will be
// fleshed out in Step 4.
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/student/home/presentation/screens/home_screen.dart';
import '../../features/student/search/presentation/screens/search_screen.dart';
import '../../features/student/search/presentation/screens/filter_screen.dart';
import '../../features/student/center_detail/presentation/screens/center_detail_screen.dart';
import '../../features/student/profile/presentation/screens/student_profile_screen.dart';
import '../../features/student/saved/presentation/screens/saved_screen.dart';
import '../../features/owner/dashboard/presentation/screens/owner_dashboard_screen.dart';
import '../../features/owner/manage_center/presentation/screens/manage_center_screen.dart';
import '../../features/owner/manage_center/presentation/screens/create_center_screen.dart';
import '../../features/owner/manage_center/presentation/screens/edit_center_screen.dart';
import '../../features/owner/enquiry_inbox/presentation/screens/enquiry_inbox_screen.dart';
import '../../features/owner/enquiry_inbox/presentation/screens/enquiry_detail_screen.dart';
import '../../features/owner/profile/presentation/screens/owner_profile_screen.dart';
import '../../features/teacher/home/presentation/screens/teacher_home_screen.dart';
import '../../features/teacher/search/presentation/screens/teacher_search_screen.dart';
import '../../features/teacher/enquiries/presentation/screens/teacher_enquiries_screen.dart';
import '../../features/teacher/schedule/presentation/screens/teacher_schedule_screen.dart';
import '../../features/teacher/profile/presentation/screens/teacher_profile_screen.dart';
import '../../features/teacher/profile/presentation/screens/edit_teacher_profile_screen.dart';

/// Builds the [GoRouter] used by the app.
///
/// Reads [roleProvider] and the Hive auth box on each redirect to decide
/// whether the requested route is reachable from the current session.
abstract final class AppRouter {
  AppRouter._();

  // Path prefixes used to classify a location as belonging to one role's shell.
  // A path matches a prefix iff `loc == prefix` or `loc` starts with `prefix/`.
  static const List<String> _studentPrefixes = <String>[
    '/home',
    '/search',
    '/center',
    '/saved',
    '/student-profile',
  ];
  static const List<String> _ownerPrefixes = <String>[
    '/dashboard',
    '/manage-center',
    '/enquiries',
    '/enquiry',
    '/owner-profile',
  ];
  static const List<String> _teacherPrefixes = <String>[
    '/teacher-home',
    '/teacher-search',
    '/teacher-enquiries',
    '/teacher-schedule',
    '/teacher-profile',
  ];

  static bool _matchesPrefix(String loc, List<String> prefixes) {
    for (final p in prefixes) {
      if (loc == p || loc.startsWith('$p/')) return true;
    }
    return false;
  }

  /// The shell-home location for a given role. Used both to land a freshly
  /// authenticated user and to bounce them out of another role's shell.
  static String _homeFor(String role) {
    if (role == roleOwner) return '/dashboard';
    if (role == roleTeacher) return '/teacher-home';
    return '/home'; // student (default)
  }

  /// Build the configured [GoRouter] instance. Called from `routerProvider`.
  static GoRouter build(Ref ref) {
    return GoRouter(
      initialLocation: '/onboarding',
      debugLogDiagnostics: false,
      redirect: (BuildContext context, GoRouterState state) {
        final role = ref.read(roleProvider);
        // Sync proxy for "has a real authenticated session": currentUserId is
        // written by AuthController.signIn/register on success and removed by
        // logout (and by ApiClient on a 401). Picking a role on onboarding
        // sets the role but does NOT set currentUserId — so the user can't
        // skip past auth by selecting a role.
        final hasSession = LocalStorage.containsKey(StorageKeys.currentUserId);

        final loc = state.matchedLocation;
        final isOnboarding = loc == '/onboarding';
        final isAuthRoute =
            loc == '/login' || loc == '/register' || loc == '/forgot-password';
        final isStudentRoute = _matchesPrefix(loc, _studentPrefixes);
        final isOwnerRoute = _matchesPrefix(loc, _ownerPrefixes);
        final isTeacherRoute = _matchesPrefix(loc, _teacherPrefixes);

        // No role yet: only onboarding / auth flow is allowed.
        if (role == null) {
          if (isOnboarding || isAuthRoute) return null;
          return '/onboarding';
        }

        // Role picked but no auth session: send to login. Onboarding and the
        // other auth routes (register, forgot-password) stay reachable so the
        // user can pick a different role or sign up.
        if (!hasSession) {
          if (isOnboarding || isAuthRoute) return null;
          return '/login';
        }

        // Role + session - kick out of onboarding / auth into the shell home.
        if (isOnboarding || isAuthRoute) {
          return _homeFor(role);
        }

        // Cross-shell guard: a role can only navigate within its own shell.
        // If the location belongs to a shell that isn't this role's, bounce
        // back to this role's home.
        final inOtherShell = (role != roleStudent && isStudentRoute) ||
            (role != roleOwner && isOwnerRoute) ||
            (role != roleTeacher && isTeacherRoute);
        if (inOtherShell) return _homeFor(role);

        return null;
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/onboarding',
          name: AppRoutes.onboarding,
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          name: AppRoutes.login,
          builder: (context, state) =>
              LoginScreen(initialRole: state.extra as String?),
        ),
        GoRoute(
          path: '/register',
          name: AppRoutes.register,
          builder: (context, state) =>
              RegisterScreen(initialRole: state.extra as String?),
        ),
        GoRoute(
          path: '/forgot-password',
          name: AppRoutes.forgotPassword,
          builder: (context, state) => const ForgotPasswordScreen(),
        ),

        // Student shell
        ShellRoute(
          builder: (context, state, child) => _StudentShell(child: child),
          routes: <RouteBase>[
            GoRoute(
              path: '/home',
              name: AppRoutes.studentHome,
              builder: (context, state) => const HomeScreen(),
            ),
            GoRoute(
              path: '/search',
              name: AppRoutes.studentSearch,
              builder: (context, state) => const SearchScreen(),
              routes: <RouteBase>[
                GoRoute(
                  path: 'filter',
                  name: AppRoutes.studentFilter,
                  builder: (context, state) => const FilterScreen(),
                ),
              ],
            ),
            GoRoute(
              path: '/center/:id',
              name: AppRoutes.studentCenterDetail,
              builder: (context, state) => CenterDetailScreen(
                centerId: state.pathParameters['id'] ?? '',
              ),
            ),
            GoRoute(
              path: '/saved',
              name: AppRoutes.studentSaved,
              builder: (context, state) => const SavedScreen(),
            ),
            GoRoute(
              path: '/student-profile',
              name: AppRoutes.studentProfile,
              builder: (context, state) => const StudentProfileScreen(),
            ),
          ],
        ),

        // Owner shell
        ShellRoute(
          builder: (context, state, child) => _OwnerShell(child: child),
          routes: <RouteBase>[
            GoRoute(
              path: '/dashboard',
              name: AppRoutes.ownerDashboard,
              builder: (context, state) => const OwnerDashboardScreen(),
            ),
            GoRoute(
              path: '/manage-center',
              name: AppRoutes.ownerManageCenter,
              builder: (context, state) => const ManageCenterScreen(),
              routes: <RouteBase>[
                GoRoute(
                  path: 'create',
                  name: AppRoutes.ownerCreateCenter,
                  builder: (context, state) => const CreateCenterScreen(),
                ),
                GoRoute(
                  path: 'edit',
                  name: AppRoutes.ownerEditCenter,
                  builder: (context, state) => const EditCenterScreen(),
                ),
              ],
            ),
            GoRoute(
              path: '/enquiries',
              name: AppRoutes.ownerEnquiryInbox,
              builder: (context, state) => const EnquiryInboxScreen(),
            ),
            GoRoute(
              path: '/enquiry/:id',
              name: AppRoutes.ownerEnquiryDetail,
              builder: (context, state) => EnquiryDetailScreen(
                enquiryId: state.pathParameters['id'] ?? '',
              ),
            ),
            GoRoute(
              path: '/owner-profile',
              name: AppRoutes.ownerProfile,
              builder: (context, state) => const OwnerProfileScreen(),
            ),
          ],
        ),

        // Teacher shell
        ShellRoute(
          builder: (context, state, child) => _TeacherShell(child: child),
          routes: <RouteBase>[
            GoRoute(
              path: '/teacher-home',
              name: AppRoutes.teacherHome,
              builder: (context, state) => const TeacherHomeScreen(),
            ),
            GoRoute(
              path: '/teacher-search',
              name: AppRoutes.teacherSearch,
              builder: (context, state) => const TeacherSearchScreen(),
            ),
            GoRoute(
              path: '/teacher-enquiries',
              name: AppRoutes.teacherEnquiries,
              builder: (context, state) => const TeacherEnquiriesScreen(),
            ),
            GoRoute(
              path: '/teacher-schedule',
              name: AppRoutes.teacherSchedule,
              builder: (context, state) => const TeacherScheduleScreen(),
            ),
            GoRoute(
              path: '/teacher-profile',
              name: AppRoutes.teacherProfile,
              builder: (context, state) => const TeacherProfileScreen(),
              routes: <RouteBase>[
                GoRoute(
                  path: 'edit',
                  name: AppRoutes.teacherEditProfile,
                  builder: (context, state) => const EditTeacherProfileScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// Adaptive-nav shell for the student role. 4 tabs: Home, Search, Saved,
/// Profile. Switches between [NavigationBar] and [NavigationRail] via
/// [AdaptiveNavigation].
class _StudentShell extends StatelessWidget {
  const _StudentShell({required this.child});

  final Widget child;

  static const List<AdaptiveDestination> _destinations = <AdaptiveDestination>[
    AdaptiveDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: AppStrings.navHome,
    ),
    AdaptiveDestination(
      icon: Icons.search,
      selectedIcon: Icons.search,
      label: AppStrings.navSearch,
    ),
    AdaptiveDestination(
      icon: Icons.bookmark_outline,
      selectedIcon: Icons.bookmark,
      label: AppStrings.navSaved,
    ),
    AdaptiveDestination(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: AppStrings.navProfile,
    ),
  ];

  static int _indexFor(String loc) {
    if (loc.startsWith('/search')) return 1;
    if (loc.startsWith('/saved')) return 2;
    if (loc.startsWith('/student-profile')) return 3;
    return 0; // `/home` and anything else.
  }

  static void _onTap(BuildContext context, int i) {
    switch (i) {
      case 0:
        context.goNamed(AppRoutes.studentHome);
      case 1:
        context.goNamed(AppRoutes.studentSearch);
      case 2:
        context.goNamed(AppRoutes.studentSaved);
      case 3:
        context.goNamed(AppRoutes.studentProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    return AdaptiveNavigation(
      destinations: _destinations,
      selectedIndex: _indexFor(loc),
      onDestinationSelected: (i) => _onTap(context, i),
      child: child,
    );
  }
}

/// Adaptive-nav shell for the coaching-owner role. 4 tabs: Dashboard, Center,
/// Enquiries, Profile. Same [AdaptiveNavigation] backing as [_StudentShell].
class _OwnerShell extends StatelessWidget {
  const _OwnerShell({required this.child});

  final Widget child;

  static const List<AdaptiveDestination> _destinations = <AdaptiveDestination>[
    AdaptiveDestination(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard,
      label: AppStrings.navDashboard,
    ),
    AdaptiveDestination(
      icon: Icons.business_outlined,
      selectedIcon: Icons.business,
      label: AppStrings.navCenter,
    ),
    AdaptiveDestination(
      icon: Icons.inbox_outlined,
      selectedIcon: Icons.inbox,
      label: AppStrings.navEnquiries,
    ),
    AdaptiveDestination(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: AppStrings.navProfile,
    ),
  ];

  static int _indexFor(String loc) {
    if (loc.startsWith('/manage-center')) return 1;
    if (loc.startsWith('/enquiries') || loc.startsWith('/enquiry/')) return 2;
    if (loc.startsWith('/owner-profile')) return 3;
    return 0; // `/dashboard`.
  }

  static void _onTap(BuildContext context, int i) {
    switch (i) {
      case 0:
        context.goNamed(AppRoutes.ownerDashboard);
      case 1:
        context.goNamed(AppRoutes.ownerManageCenter);
      case 2:
        context.goNamed(AppRoutes.ownerEnquiryInbox);
      case 3:
        context.goNamed(AppRoutes.ownerProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    return AdaptiveNavigation(
      destinations: _destinations,
      selectedIndex: _indexFor(loc),
      onDestinationSelected: (i) => _onTap(context, i),
      child: child,
    );
  }
}

/// Adaptive-nav shell for the teacher role. 5 tabs: Home, Search, Enquiries,
/// Schedule, Profile. Same [AdaptiveNavigation] backing as the other shells.
class _TeacherShell extends StatelessWidget {
  const _TeacherShell({required this.child});

  final Widget child;

  static const List<AdaptiveDestination> _destinations = <AdaptiveDestination>[
    AdaptiveDestination(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      label: AppStrings.navHome,
    ),
    AdaptiveDestination(
      icon: Icons.search,
      selectedIcon: Icons.search,
      label: AppStrings.navSearch,
    ),
    AdaptiveDestination(
      icon: Icons.inbox_outlined,
      selectedIcon: Icons.inbox,
      label: AppStrings.navEnquiries,
    ),
    AdaptiveDestination(
      icon: Icons.calendar_month_outlined,
      selectedIcon: Icons.calendar_month,
      label: AppStrings.navSchedule,
    ),
    AdaptiveDestination(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: AppStrings.navProfile,
    ),
  ];

  static int _indexFor(String loc) {
    if (loc.startsWith('/teacher-search')) return 1;
    if (loc.startsWith('/teacher-enquiries')) return 2;
    if (loc.startsWith('/teacher-schedule')) return 3;
    if (loc.startsWith('/teacher-profile')) return 4;
    return 0; // `/teacher-home`.
  }

  static void _onTap(BuildContext context, int i) {
    switch (i) {
      case 0:
        context.goNamed(AppRoutes.teacherHome);
      case 1:
        context.goNamed(AppRoutes.teacherSearch);
      case 2:
        context.goNamed(AppRoutes.teacherEnquiries);
      case 3:
        context.goNamed(AppRoutes.teacherSchedule);
      case 4:
        context.goNamed(AppRoutes.teacherProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    return AdaptiveNavigation(
      destinations: _destinations,
      selectedIndex: _indexFor(loc),
      onDestinationSelected: (i) => _onTap(context, i),
      child: child,
    );
  }
}
