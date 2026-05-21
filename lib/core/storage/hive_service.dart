/// Hive initialisation, box opening, and adapter registration.
library;

import 'package:hive_flutter/hive_flutter.dart';

import '../constants/hive_keys.dart';

/// Wraps Hive setup. Owns initialisation, adapter registration, and access to
/// the named boxes used throughout the app.
///
/// [init] is called once from `main.dart` before `runApp`.
class HiveService {
  HiveService._();

  /// Singleton instance. Exposed via [hiveServiceProvider] for the rest of the app.
  static final HiveService instance = HiveService._();

  bool _initialised = false;

  /// Initialise Hive, register model adapters, and open the named boxes.
  /// Safe to call multiple times.
  Future<void> init() async {
    if (_initialised) return;

    await Hive.initFlutter();

    // TODO(adapters): register @HiveType adapters here once feature models exist.
    //   e.g. Hive.registerAdapter(UserModelAdapter());
    //   Type IDs will be allocated in a future decision record.

    await Future.wait<void>([
      Hive.openBox<dynamic>(HiveKeys.boxSettings),
      Hive.openBox<dynamic>(HiveKeys.boxAuth),
      Hive.openBox<dynamic>(HiveKeys.boxCache),
    ]);

    _initialised = true;
  }

  /// Settings box - app-wide preferences (user role, theme mode, etc.).
  Box<dynamic> get settingsBox => Hive.box<dynamic>(HiveKeys.boxSettings);

  /// Auth box - JWT token and cached current user.
  Box<dynamic> get authBox => Hive.box<dynamic>(HiveKeys.boxAuth);

  /// Cache box - opportunistic caching of remote data.
  Box<dynamic> get cacheBox => Hive.box<dynamic>(HiveKeys.boxCache);
}
