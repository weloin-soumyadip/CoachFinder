/// Application entry point.
///
/// Initialises [LocalStorage], hydrates the role + theme from local storage,
/// then mounts the [CoachFinderApp] inside a Riverpod [ProviderScope].
library;

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'core/constants/app_strings.dart';
import 'core/providers/role_provider.dart';
import 'core/providers/theme_mode_provider.dart';
import 'core/router/router_provider.dart';
import 'core/storage/local_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/providers/auth_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await LocalStorage.init();

  final initialRole = LocalStorage.get<String>(StorageKeys.userRole);
  final initialThemeMode = themeModeFromStorage(
    LocalStorage.get<String>(StorageKeys.themeMode),
  );

  runApp(
    ProviderScope(
      overrides: <Override>[
        roleProvider.overrideWith((ref) => initialRole),
        themeModeProvider.overrideWith((ref) => initialThemeMode),
      ],
      child: const CoachFinderApp(),
    ),
  );
}

/// Root [MaterialApp] for CoachFinder. Wires the [GoRouter] from
/// [routerProvider] and kicks off the auth controller's launch-time
/// `/me` rehydration via [useEffect].
class CoachFinderApp extends HookConsumerWidget {
  const CoachFinderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Touch (don't watch) the auth controller so its `bootstrap()` fires
    // once, without subscribing this widget to every AuthState transition.
    // The router redirect reads `roleProvider` directly on each navigation,
    // so rehydration changes propagate without rebuilding `MaterialApp`.
    useEffect(() {
      ref.read(authControllerProvider);
      return null;
    }, const <Object?>[]);

    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
