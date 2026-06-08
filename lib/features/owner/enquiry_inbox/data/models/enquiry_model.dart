/// Owner enquiry model, parsed from the `/api/owners/enquiries*` endpoints.
/// An enquiry is a single student message + a status + private owner notes —
/// there is no reply/conversation thread on the backend.
library;

/// Lifecycle state of an enquiry (backend `new` → `contacted` → `closed`).
enum EnquiryStatus {
  /// Newly received, not yet actioned (effectively "unread").
  newEnquiry('new'),

  /// The owner has reached out.
  contacted('contacted'),

  /// Conversation concluded.
  closed('closed');

  const EnquiryStatus(this.wireValue);

  /// The exact string the backend accepts / returns.
  final String wireValue;

  /// Parses a wire value, defaulting to [newEnquiry] when unknown/null.
  static EnquiryStatus fromWire(String? value) {
    for (final EnquiryStatus s in values) {
      if (s.wireValue == value) return s;
    }
    return EnquiryStatus.newEnquiry;
  }
}

/// Inbox filter selection — the [EnquiryStatus] values plus an "all" option.
enum EnquiryFilter {
  /// No status filter.
  all,

  /// Only `new`.
  newEnquiry,

  /// Only `contacted`.
  contacted,

  /// Only `closed`.
  closed;

  /// The backing status, or null for [all] (sent as the `status` query param).
  EnquiryStatus? get status => switch (this) {
        EnquiryFilter.all => null,
        EnquiryFilter.newEnquiry => EnquiryStatus.newEnquiry,
        EnquiryFilter.contacted => EnquiryStatus.contacted,
        EnquiryFilter.closed => EnquiryStatus.closed,
      };
}

/// A single student enquiry to the owner's centre.
class Enquiry {
  /// Creates an enquiry.
  const Enquiry({
    required this.id,
    required this.studentName,
    this.studentPhone,
    this.studentEmail,
    this.subjectName,
    required this.message,
    required this.status,
    this.ownerNotes,
    this.createdAt,
    this.updatedAt,
  });

  /// Enquiry `_id`.
  final String id;

  /// Student display name.
  final String studentName;

  /// Student phone, or null.
  final String? studentPhone;

  /// Student email, or null.
  final String? studentEmail;

  /// Subject name the enquiry is about, or null.
  final String? subjectName;

  /// The student's message.
  final String message;

  /// Lifecycle status.
  final EnquiryStatus status;

  /// Private owner notes (never shown to the student), or null.
  final String? ownerNotes;

  /// Created timestamp, or null.
  final DateTime? createdAt;

  /// Last-updated timestamp, or null.
  final DateTime? updatedAt;

  /// First letter of the student name (avatar initial).
  String get initial =>
      studentName.trim().isEmpty ? '?' : studentName.trim()[0].toUpperCase();

  /// Parses one enquiry doc (with populated `student` + `subject`).
  factory Enquiry.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> student =
        (json['student'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    final Map<String, dynamic>? subject =
        json['subject'] as Map<String, dynamic>?;
    final String name = (student['name'] as String?)?.trim() ?? '';
    return Enquiry(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      studentName: name.isEmpty ? 'Student' : name,
      studentPhone: _nullableString(student['phone']),
      studentEmail: _nullableString(student['email']),
      subjectName: _nullableString(subject?['name']),
      message: (json['message'] as String?) ?? '',
      status: EnquiryStatus.fromWire(json['status'] as String?),
      ownerNotes: _nullableString(json['ownerNotes']),
      createdAt: DateTime.tryParse((json['createdAt'] ?? '').toString()),
      updatedAt: DateTime.tryParse((json['updatedAt'] ?? '').toString()),
    );
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final String s = value.toString().trim();
    return s.isEmpty ? null : s;
  }
}
