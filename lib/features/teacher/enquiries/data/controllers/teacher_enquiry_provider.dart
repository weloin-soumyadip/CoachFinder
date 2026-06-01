/// TeacherEnquiryNotifier and teacherEnquiriesProvider for the teacher enquiry
/// inbox/detail.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../mock_teacher_enquiry_data.dart';

/// Holds the teacher's enquiries as mutable in-memory state so the inbox list
/// and the detail screen share a single source of truth across navigation: a
/// reply or a status change made in the detail view is reflected immediately in
/// the inbox.
///
/// Phase 1 seeds from fixtures; when the backend lands, [build] becomes a
/// repository fetch and the mutators post to the API.
class TeacherEnquiryNotifier extends Notifier<List<TeacherEnquiry>> {
  @override
  List<TeacherEnquiry> build() =>
      List<TeacherEnquiry>.from(mockTeacherEnquiries);

  /// The enquiry with [id], or `null` if none matches.
  TeacherEnquiry? byId(String id) {
    for (final TeacherEnquiry e in state) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Append a teacher reply to [id]'s thread and mark the enquiry replied.
  /// No-op for blank text.
  void addReply(String id, String text) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return;
    state = <TeacherEnquiry>[
      for (final TeacherEnquiry e in state)
        if (e.id == id)
          e.copyWith(
            thread: <TeacherEnquiryMessage>[
              ...e.thread,
              TeacherEnquiryMessage(
                text: trimmed,
                fromTeacher: true,
                timeLabel: AppStrings.enquiryReplyJustNow,
              ),
            ],
            status: TeacherEnquiryStatus.replied,
            timeAgo: AppStrings.enquiryReplyJustNow,
          )
        else
          e,
    ];
  }

  /// Move [id] to the archived state.
  void archive(String id) => _setStatus(id, TeacherEnquiryStatus.archived);

  /// Restore [id] from archived: back to replied if it already has a teacher
  /// reply, otherwise back to new.
  void unarchive(String id) {
    final TeacherEnquiry? e = byId(id);
    if (e == null) return;
    final bool hasReply =
        e.thread.any((TeacherEnquiryMessage m) => m.fromTeacher);
    _setStatus(
      id,
      hasReply ? TeacherEnquiryStatus.replied : TeacherEnquiryStatus.newEnquiry,
    );
  }

  void _setStatus(String id, TeacherEnquiryStatus status) {
    state = <TeacherEnquiry>[
      for (final TeacherEnquiry e in state)
        if (e.id == id) e.copyWith(status: status) else e,
    ];
  }
}

/// App-wide access to the teacher's enquiries.
final NotifierProvider<TeacherEnquiryNotifier, List<TeacherEnquiry>>
    teacherEnquiriesProvider =
    NotifierProvider<TeacherEnquiryNotifier, List<TeacherEnquiry>>(
  TeacherEnquiryNotifier.new,
);
