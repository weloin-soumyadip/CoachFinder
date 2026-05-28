/// Static Hive-backed key-value store and the constants for its keys.
library;

import 'package:hive_flutter/hive_flutter.dart';

/// App-wide settings store backed by a single Hive box. Mirrors the
/// `LocalStorage` pattern used in the user's other Flutter project so the two
/// codebases share a single mental model.
///
/// Call [init] once from `main` before any reads or writes.
class LocalStorage {
  static const String _boxName = 'coachfinder_settings';
  static Box? _box;

  /// Opens the single backing Hive box. Idempotent — safe to call multiple
  /// times.
  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  /// Reads the value stored under [key], or [defaultValue] when absent.
  /// Returns null when the store hasn't been initialised yet.
  static T? get<T>(String key, {T? defaultValue}) {
    return _box?.get(key, defaultValue: defaultValue) as T?;
  }

  /// Writes [value] under [key]. No-op when [init] hasn't been called.
  static Future<void> set<T>(String key, T value) async {
    await _box?.put(key, value);
  }

  /// Deletes the entry under [key], if any.
  static Future<void> remove(String key) async {
    await _box?.delete(key);
  }

  /// Wipes every entry in the box (used by test setup; rarely in app code).
  static Future<void> clear() async {
    await _box?.clear();
  }

  /// True iff [key] is present in the box.
  static bool containsKey(String key) => _box?.containsKey(key) ?? false;
}

/// String constants for every key written through [LocalStorage]. Centralised
/// so refactors don't drift through hard-coded strings.
class StorageKeys {
  StorageKeys._();

  /// Persisted ThemeMode (one of `'light'`, `'dark'`, `'system'`).
  static const String themeMode = 'theme_mode';

  /// Active user role (one of `'student'`, `'owner'`, `'teacher'`).
  static const String userRole = 'user_role';

  /// Mongo ObjectId of the currently authenticated user, captured from the
  /// last `/auth/register` (or `/auth/login`, future round) response.
  static const String currentUserId = 'current_user_id';
}
