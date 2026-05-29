/// ManageCenterNotifier and manageCenterProvider for the owner's center.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mock_center_data.dart';

/// Holds the owner's [CenterProfile] as in-memory state so the read view and
/// the edit form share one source of truth: saving an edit updates the profile
/// the tab displays.
///
/// Phase 1 seeds from the fixture; when the backend lands, [build] becomes a
/// repository fetch and [save] posts the update.
class ManageCenterNotifier extends Notifier<CenterProfile> {
  @override
  CenterProfile build() => mockCenter;

  /// Replace the whole profile with an edited copy.
  void save(CenterProfile updated) => state = updated;
}

/// App-wide access to the owner's center profile.
final NotifierProvider<ManageCenterNotifier, CenterProfile>
    manageCenterProvider =
    NotifierProvider<ManageCenterNotifier, CenterProfile>(
  ManageCenterNotifier.new,
);
