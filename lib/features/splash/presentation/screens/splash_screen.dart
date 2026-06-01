/// Initial route — branded reveal that waits for auth bootstrap, then
/// routes to the first real screen.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/providers/role_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/brand_backdrop.dart';
import '../../../../shared/widgets/neo_surface.dart';
import '../../../auth/data/providers/auth_providers.dart';

/// The first widget that renders on launch.
///
/// Watches [authControllerProvider] — its first read fires
/// `AuthController.bootstrap()`, which validates the cached access token
/// against `GET /api/auth/me`. As soon as bootstrap settles (or drops back
/// to `initial` after a network failure), the splash routes to the right
/// first screen and pops itself out of the back stack.
///
/// Routing logic (see [_routeFromHere]):
///   - `AuthState.authenticated` + role → role's shell home.
///   - `AuthState.unauthenticated` → login if a role is cached, else
///     onboarding.
///   - Stalled (still `initial` after the 4 s safety timer) → trust
///     [LocalStorage]: cached session → role shell; cached role only →
///     login; otherwise onboarding.
///
/// **Cold-start subtlety.** `bootstrap()` is `async` but the no-cached-id
/// branch returns *synchronously* (no `await` before
/// `state = unauthenticated`). The transition happens before this widget's
/// `ref.listen` can register, so the listener never sees it. The
/// `useEffect` below detects the already-terminal status and schedules the
/// same min-show + navigate pipeline.
///
/// **Disposal safety.** Both the `ref.listen` callback and the safety
/// `Timer` schedule navigation via `Future.delayed` (for the min-show) or
/// the timer's own delay. Each path captures the auth state + role
/// **at scheduling time** (when `ref` is definitely live) and passes them
/// to `navigateNow` as parameters, so the delayed callback never reads
/// `ref` after the element may have been disposed.
class SplashScreen extends HookConsumerWidget {
  const SplashScreen({super.key});

  /// Min time the splash stays visible after bootstrap settles — keeps the
  /// brand from flashing on cold starts with no cached session.
  static const Duration _minShow = Duration(milliseconds: 600);

  /// Max time the splash will wait for bootstrap to settle before falling
  /// back to the cached state. Covers `AuthStatus.initial` stalls from
  /// network failures during `/me` rehydration.
  static const Duration _maxWait = Duration(seconds: 4);

  /// Visual sizing — kept local since these don't belong in the shared
  /// `AppSpacing` / `AppEffects` token sets.
  static const double _logoSize = 56;
  static const double _spinnerSize = 28;
  static const double _spinnerStroke = 2.5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final textTheme = Theme.of(context).textTheme;
    final navigated = useState<bool>(false);
    final timerRef = useRef<Timer?>(null);

    // First watch constructs the controller (firing bootstrap) and re-runs
    // build on each AuthState transition. We use the captured `authState`
    // below; the comment about "rebuilds when bootstrap finishes" was
    // misleading — the rebuild is what lets the cold-start `useEffect`
    // observe an already-terminal state.
    final authState = ref.watch(authControllerProvider);

    void navigateNow({required AuthState auth, required String? role}) {
      if (navigated.value || !context.mounted) return;
      navigated.value = true;
      timerRef.value?.cancel();
      _routeFromHere(context, auth: auth, cachedRole: role);
    }

    // Bootstrap transitioned (loading → terminal, or loading → initial on
    // a network failure). Capture role *now* — while `ref` is definitely
    // live — and pass both values to the delayed `navigateNow`.
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      final wasLoading = previous?.status == AuthStatus.loading;
      final settled = next.status == AuthStatus.authenticated ||
          next.status == AuthStatus.unauthenticated;
      final droppedToInitial = wasLoading && next.status == AuthStatus.initial;
      if (!settled && !droppedToInitial) return;
      final roleSnapshot = ref.read(roleProvider);
      Future<void>.delayed(_minShow, () {
        navigateNow(auth: next, role: roleSnapshot);
      });
    });

    // Cold-start path + safety timer.
    //
    // The cold-start case: when there is no cached `currentUserId`,
    // `bootstrap()` flips state to `unauthenticated` *synchronously*
    // before the controller is returned. That transition happens before
    // `ref.listen` subscribes above, so the listener never fires for it.
    // Detect the already-terminal state at mount and schedule the same
    // min-show + navigate.
    //
    // The safety timer covers the network-failure stall path documented
    // in ADR 0032 (bootstrap drops back to `initial` but no transition
    // is observable from the splash side).
    useEffect(() {
      final terminalAtMount = authState.status == AuthStatus.authenticated ||
          authState.status == AuthStatus.unauthenticated;
      if (terminalAtMount) {
        final roleSnapshot = ref.read(roleProvider);
        Future<void>.delayed(_minShow, () {
          navigateNow(auth: authState, role: roleSnapshot);
        });
      }
      timerRef.value = Timer(_maxWait, () {
        navigateNow(
          auth: ref.read(authControllerProvider),
          role: ref.read(roleProvider),
        );
      });
      return () => timerRef.value?.cancel();
    }, const <Object?>[]);

    return Scaffold(
      backgroundColor: palette.background,
      body: BrandBackdrop(
        orbColors: const <Color>[
          AppColors.studentPrimary,
          AppColors.studentPrimaryDark,
        ],
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                NeoSurface(
                  padding: const EdgeInsets.all(AppSpacing.sp24),
                  child: const Icon(
                    Icons.school_outlined,
                    size: _logoSize,
                    color: AppColors.studentPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sp24),
                Text(
                  AppStrings.appName,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sp8),
                Text(
                  AppStrings.splashTagline,
                  style: textTheme.bodyMedium?.copyWith(
                    color: palette.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.sp32),
                const SizedBox(
                  width: _spinnerSize,
                  height: _spinnerSize,
                  child: CircularProgressIndicator(
                    strokeWidth: _spinnerStroke,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.studentPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Picks the first real screen based on the settled [AuthState] and the
  /// cached role. Takes captured values (not a `WidgetRef`) so it can run
  /// from a delayed callback without touching `ref` after the splash
  /// element may have been disposed.
  static void _routeFromHere(
    BuildContext context, {
    required AuthState auth,
    required String? cachedRole,
  }) {
    if (auth.status == AuthStatus.authenticated && auth.role != null) {
      context.goNamed(landingRouteForRole(auth.role!));
      return;
    }

    if (auth.status == AuthStatus.unauthenticated) {
      context.goNamed(
        cachedRole == null ? AppRoutes.onboarding : AppRoutes.login,
      );
      return;
    }

    // Stalled bootstrap (network failure) — fall back to the cached
    // disk state the router already trusts elsewhere.
    final hasSession = LocalStorage.containsKey(StorageKeys.currentUserId);
    if (hasSession && cachedRole != null) {
      context.goNamed(landingRouteForRole(cachedRole));
      return;
    }
    context.goNamed(
      cachedRole == null ? AppRoutes.onboarding : AppRoutes.login,
    );
  }
}
