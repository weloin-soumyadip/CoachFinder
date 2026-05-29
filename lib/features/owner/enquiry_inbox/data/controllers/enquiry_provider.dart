/// EnquiryNotifier and enquiriesProvider for the owner enquiry inbox/detail.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/constants/app_strings.dart';
import '../mock_enquiry_data.dart';

/// Holds the owner's enquiries as mutable in-memory state so the inbox list and
/// the detail screen share a single source of truth across navigation: a reply
/// or a status change made in the detail view is reflected immediately in the
/// inbox.
///
/// Phase 1 seeds from fixtures; when the backend lands, [build] becomes a
/// repository fetch and the mutators post to the API.
class EnquiryNotifier extends Notifier<List<Enquiry>> {
  @override
  List<Enquiry> build() => List<Enquiry>.from(mockEnquiries);

  /// The enquiry with [id], or `null` if none matches.
  Enquiry? byId(String id) {
    for (final Enquiry e in state) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Append an owner reply to [id]'s thread and mark the enquiry replied.
  /// No-op for blank text.
  void addReply(String id, String text) {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return;
    state = <Enquiry>[
      for (final Enquiry e in state)
        if (e.id == id)
          e.copyWith(
            thread: <EnquiryMessage>[
              ...e.thread,
              EnquiryMessage(
                text: trimmed,
                fromOwner: true,
                timeLabel: AppStrings.enquiryReplyJustNow,
              ),
            ],
            status: EnquiryStatus.replied,
            timeAgo: AppStrings.enquiryReplyJustNow,
          )
        else
          e,
    ];
  }

  /// Move [id] to the archived state.
  void archive(String id) => _setStatus(id, EnquiryStatus.archived);

  /// Restore [id] from archived: back to replied if it already has an owner
  /// reply, otherwise back to new.
  void unarchive(String id) {
    final Enquiry? e = byId(id);
    if (e == null) return;
    final bool hasReply = e.thread.any((EnquiryMessage m) => m.fromOwner);
    _setStatus(
      id,
      hasReply ? EnquiryStatus.replied : EnquiryStatus.newEnquiry,
    );
  }

  void _setStatus(String id, EnquiryStatus status) {
    state = <Enquiry>[
      for (final Enquiry e in state)
        if (e.id == id) e.copyWith(status: status) else e,
    ];
  }
}

/// App-wide access to the owner's enquiries.
final NotifierProvider<EnquiryNotifier, List<Enquiry>> enquiriesProvider =
    NotifierProvider<EnquiryNotifier, List<Enquiry>>(EnquiryNotifier.new);
