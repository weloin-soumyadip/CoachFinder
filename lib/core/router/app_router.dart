/// GoRouter configuration with student and owner shells and redirect guards.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/layouts/adaptive_navigation.dart';
import '../constants/app_strings.dart';
import '../constants/hive_keys.dart';
import '../providers/role_provider.dart';
import '../storage/hive_service_provider.dart';
import 'app_routes.dart';

// Feature screens. These are placeholder Scaffolds at this point and will be
// fleshed out in Step 4.
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/student/home/presentation/screens/home_screen.dart';
import '../../features/student/search/presentation/screens/search_screen.dart';
import '../../features/student/search/presentation/screens/filter_screen.dart';
import '../../features/student/center_detail/presentation/screens/center_detail_screen.dart';
import '../../features/student/profile/presentation/screens/student_profile_screen.dart';
import '../../features/student/profile/presentation/screens/saved_screen.dart';
import '../../features/owner/dashboard/presentation/screens/owner_dashboard_screen.dart';
import '../../features/owner/manage_center/presentation/screens/manage_center_screen.dart';
import '../../features/owner/manage_center/presentation/screens/create_center_screen.dart';
import '../../features/owner/enquiry_inbox/presentation/screens/enquiry_inbox_screen.dart';
import '../../features/owner/enquiry_inbox/presentation/screens/enquiry_detail_screen.dart';

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
  ];

  static bool _matchesPrefix(String loc, List<String> prefixes) {
    for (final p in prefixes) {
      if (loc == p || loc.startsWith('$p/')) return true;
    }
    return false;
  }

  /// Build the configured [GoRouter] instance. Called from `routerProvider`.
  static GoRouter build(Ref ref) {
    return GoRouter(
      initialLocation: '/onboarding',
      debugLogDiagnostics: false,
      redirect: (BuildContext context, GoRouterState state) {
        final hive = ref.read(hiveServiceProvider);
        final token = hive.authBox.get(HiveKeys.keyJwtToken) as String?;
        final role = ref.read(roleProvider);

        final loc = state.matchedLocation;
        final isOnboarding = loc == '/onboarding';
        final isAuthRoute = loc == '/login' || loc == '/register';
        final isStudentRoute = _matchesPrefix(loc, _studentPrefixes);
        final isOwnerRoute = _matchesPrefix(loc, _ownerPrefixes);

        // No token: only the onboarding / auth flow is allowed.
        if (token == null || token.isEmpty) {
          if (isOnboarding || isAuthRoute) return null;
          return '/onboarding';
        }

        // Token but no role: impossible state - clear session and re-onboard.
        if (role == null) {
          hive.authBox.delete(HiveKeys.keyJwtToken);
          hive.authBox.delete(HiveKeys.keyCurrentUser);
          return '/onboarding';
        }

        // Token + role - kick out of onboarding / auth into the shell home.
        if (isOnboarding || isAuthRoute) {
          return role == roleStudent ? '/home' : '/dashboard';
        }

        // Cross-shell guard: roles can only navigate within their own shell.
        if (role == roleStudent && isOwnerRoute) return '/home';
        if (role == roleOwner && isStudentRoute) return '/dashboard';

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

/// Adaptive-nav shell for the coaching-owner role. 3 tabs: Dashboard, Center,
/// Enquiries. Same [AdaptiveNavigation] backing as [_StudentShell].
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
  ];

  static int _indexFor(String loc) {
    if (loc.startsWith('/manage-center')) return 1;
    if (loc.startsWith('/enquiries') || loc.startsWith('/enquiry/')) return 2;
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
