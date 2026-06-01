/// Models + fixtures backing the teacher Enquiries inbox & detail until the
/// backend lands. A teacher (independent tutor) receives direct enquiries from
/// students; this mirrors the owner enquiry model, teal-branded.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Lifecycle state of an enquiry, driving the inbox filter tabs, the tile's
/// unread treatment, and the detail status chip / archive action.
enum TeacherEnquiryStatus { newEnquiry, replied, archived }

/// Inbox filter selection - the [TeacherEnquiryStatus] values plus "all".
enum TeacherEnquiryFilter { all, newEnquiry, replied, archived }

/// One message in an enquiry thread: the student's enquiry or a teacher reply.
class TeacherEnquiryMessage {
  const TeacherEnquiryMessage({
    required this.text,
    required this.fromTeacher,
    required this.timeLabel,
  });

  /// Message body.
  final String text;

  /// True when sent by the teacher (right-aligned, teal bubble).
  final bool fromTeacher;

  /// Pre-formatted timestamp label, e.g. "2h ago" / "Just now".
  final String timeLabel;
}

/// A student enquiry plus its conversation thread.
class TeacherEnquiry {
  const TeacherEnquiry({
    required this.id,
    required this.studentName,
    required this.initial,
    required this.avatarColor,
    required this.subject,
    required this.timeAgo,
    required this.status,
    required this.phone,
    required this.email,
    required this.thread,
  });

  /// Stable id, used by the enquiry-detail route.
  final String id;

  /// Sender's display name.
  final String studentName;

  /// Avatar initial.
  final String initial;

  /// Avatar background colour (fixture content colour).
  final Color avatarColor;

  /// Subject the student is asking about, e.g. "Physics tuition".
  final String subject;

  /// Pre-formatted relative time of the latest message.
  final String timeAgo;

  /// Current lifecycle state.
  final TeacherEnquiryStatus status;

  /// Student's phone number.
  final String phone;

  /// Student's email address.
  final String email;

  /// Ordered messages, oldest first; element 0 is the student's enquiry.
  final List<TeacherEnquiryMessage> thread;

  /// First message text - the enquiry snippet shown in the inbox tile.
  String get preview => thread.isEmpty ? '' : thread.first.text;

  /// A copy with selected fields replaced.
  TeacherEnquiry copyWith({
    TeacherEnquiryStatus? status,
    List<TeacherEnquiryMessage>? thread,
    String? timeAgo,
  }) {
    return TeacherEnquiry(
      id: id,
      studentName: studentName,
      initial: initial,
      avatarColor: avatarColor,
      subject: subject,
      timeAgo: timeAgo ?? this.timeAgo,
      status: status ?? this.status,
      phone: phone,
      email: email,
      thread: thread ?? this.thread,
    );
  }
}

// ===== FIXTURES =====

/// Seed enquiries for the signed-in teacher. The first three back the home
/// tab's "Recent Enquiries" preview, so the two screens stay consistent.
const List<TeacherEnquiry> mockTeacherEnquiries = <TeacherEnquiry>[
  TeacherEnquiry(
    id: 'enq-t1',
    studentName: 'Aarav Sharma',
    initial: 'A',
    avatarColor: AppColors.studentPrimary,
    subject: 'Physics tuition',
    timeAgo: '2h ago',
    status: TeacherEnquiryStatus.newEnquiry,
    phone: '+91 98765 43210',
    email: 'aarav.sharma@example.com',
    thread: <TeacherEnquiryMessage>[
      TeacherEnquiryMessage(
        text: 'Hi sir, do you take one-on-one Physics tuition for Class 12? I '
            'need help with mechanics and electrostatics before my boards.',
        fromTeacher: false,
        timeLabel: '2h ago',
      ),
    ],
  ),
  TeacherEnquiry(
    id: 'enq-t2',
    studentName: 'Diya Mehta',
    initial: 'D',
    avatarColor: AppColors.ownerAccent,
    subject: 'Maths · JEE prep',
    timeAgo: '5h ago',
    status: TeacherEnquiryStatus.newEnquiry,
    phone: '+91 91234 56780',
    email: 'diya.mehta@example.com',
    thread: <TeacherEnquiryMessage>[
      TeacherEnquiryMessage(
        text: 'Hello, what are your charges for JEE Maths coaching, and do you '
            'run weekend batches?',
        fromTeacher: false,
        timeLabel: '5h ago',
      ),
    ],
  ),
  TeacherEnquiry(
    id: 'enq-t3',
    studentName: 'Kabir Rao',
    initial: 'K',
    avatarColor: AppColors.teacherAccent,
    subject: 'Physics · board exam',
    timeAgo: '1d ago',
    status: TeacherEnquiryStatus.replied,
    phone: '+91 99887 76655',
    email: 'kabir.rao@example.com',
    thread: <TeacherEnquiryMessage>[
      TeacherEnquiryMessage(
        text: 'Do you provide notes and practice papers for board Physics?',
        fromTeacher: false,
        timeLabel: '1d ago',
      ),
      TeacherEnquiryMessage(
        text: 'Hi Kabir! Yes, every student gets my full set of board-focused '
            'notes plus weekly practice papers. Want to join a trial session?',
        fromTeacher: true,
        timeLabel: '1d ago',
      ),
    ],
  ),
  TeacherEnquiry(
    id: 'enq-t4',
    studentName: 'Ishita Nair',
    initial: 'I',
    avatarColor: Color(0xFF8E7CC3),
    subject: 'Maths · Class 10',
    timeAgo: '3 days ago',
    status: TeacherEnquiryStatus.replied,
    phone: '+91 90011 22334',
    email: 'ishita.nair@example.com',
    thread: <TeacherEnquiryMessage>[
      TeacherEnquiryMessage(
        text: 'Can my daughter join your Class 10 Maths batch mid-term?',
        fromTeacher: false,
        timeLabel: '3 days ago',
      ),
      TeacherEnquiryMessage(
        text:
            'Absolutely - I run short catch-up sessions for mid-term joiners. '
            'She can start this week.',
        fromTeacher: true,
        timeLabel: '2 days ago',
      ),
    ],
  ),
  TeacherEnquiry(
    id: 'enq-t5',
    studentName: 'Rohan Das',
    initial: 'R',
    avatarColor: Color(0xFFB07D62),
    subject: 'Physics · online',
    timeAgo: '1 week ago',
    status: TeacherEnquiryStatus.archived,
    phone: '+91 98200 11223',
    email: 'rohan.das@example.com',
    thread: <TeacherEnquiryMessage>[
      TeacherEnquiryMessage(
        text: 'Are your Physics sessions available online?',
        fromTeacher: false,
        timeLabel: '1 week ago',
      ),
      TeacherEnquiryMessage(
        text: 'Yes, I teach both online and in person - whichever suits you.',
        fromTeacher: true,
        timeLabel: '6 days ago',
      ),
    ],
  ),
];
