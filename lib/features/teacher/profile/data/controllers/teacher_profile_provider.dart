/// TeacherProfileNotifier and teacherProfileProvider for the teacher profile.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../mock_teacher_profile_data.dart';

/// Holds the teacher's [TeacherProfile] as in-memory state so the read view and
/// the edit form share one source of truth: saving an edit updates the profile
/// the tab displays.
///
/// Phase 1 seeds from the fixture; when the backend lands, [build] becomes a
/// repository fetch and [save] posts the update.
class TeacherProfileNotifier extends Notifier<TeacherProfile> {
  @override
  TeacherProfile build() => mockTeacherProfile;

  /// Replace the whole profile with an edited copy.
  void save(TeacherProfile updated) => state = updated;
}

/// App-wide access to the teacher's profile.
final NotifierProvider<TeacherProfileNotifier, TeacherProfile>
    teacherProfileProvider =
    NotifierProvider<TeacherProfileNotifier, TeacherProfile>(
  TeacherProfileNotifier.new,
);
