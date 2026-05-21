/// Riverpod Provider exposing the configured GoRouter.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';

/// Exposes the configured [GoRouter] for the app.
///
/// [AppRouter.build] reads other providers (role, auth) so route decisions
/// stay reactive to changes.
final Provider<GoRouter> routerProvider = Provider<GoRouter>(
  (ref) => AppRouter.build(ref),
);
