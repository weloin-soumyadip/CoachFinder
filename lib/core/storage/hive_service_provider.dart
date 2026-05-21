/// Riverpod Provider exposing the HiveService.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'hive_service.dart';

/// Exposes the singleton [HiveService]. [HiveService.init] must already have been
/// called in `main.dart` before any consumer reads this provider.
final Provider<HiveService> hiveServiceProvider = Provider<HiveService>(
  (ref) => HiveService.instance,
);
