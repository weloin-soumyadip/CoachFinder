/// Models + fixtures backing the owner Enquiries inbox & detail until the
/// backend lands.
library;

import 'package:flutter/material.dart';

/// Lifecycle state of an enquiry, driving the inbox filter tabs, the tile's
/// unread treatment, and the detail status chip / archive action.
enum EnquiryStatus { newEnquiry, replied, archived }

/// Inbox filter selection - the [EnquiryStatus] values plus an "all" option.
enum EnquiryFilter { all, newEnquiry, replied, archived }

/// One message in an enquiry thread: the student's enquiry or an owner reply.
class EnquiryMessage {
  const EnquiryMessage({
    required this.text,
    required this.fromOwner,
    required this.timeLabel,
  });

  /// Message body.
  final String text;

  /// True when sent by the owner (right-aligned, accent bubble).
  final bool fromOwner;

  /// Pre-formatted timestamp label, e.g. "2h ago" / "Just now".
  final String timeLabel;
}

/// A student enquiry plus its conversation thread.
class Enquiry {
  const Enquiry({
    required this.id,
    required this.studentName,
    required this.initial,
    required this.avatarColor,
    required this.course,
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

  /// Course / subject the student is asking about.
  final String course;

  /// Pre-formatted relative time of the latest message.
  final String timeAgo;

  /// Current lifecycle state.
  final EnquiryStatus status;

  /// Student's phone number.
  final String phone;

  /// Student's email address.
  final String email;

  /// Ordered messages, oldest first; element 0 is the student's enquiry.
  final List<EnquiryMessage> thread;

  /// First message text - the enquiry snippet shown in the inbox tile.
  String get preview => thread.isEmpty ? '' : thread.first.text;

  /// A copy with selected fields replaced.
  Enquiry copyWith({
    EnquiryStatus? status,
    List<EnquiryMessage>? thread,
    String? timeAgo,
  }) {
    return Enquiry(
      id: id,
      studentName: studentName,
      initial: initial,
      avatarColor: avatarColor,
      course: course,
      timeAgo: timeAgo ?? this.timeAgo,
      status: status ?? this.status,
      phone: phone,
      email: email,
      thread: thread ?? this.thread,
    );
  }
}

// ===== FIXTURES =====

/// Seed enquiries. The first three ids match the dashboard's recent-enquiries
/// preview so tapping through from the dashboard resolves to a real enquiry.
const List<Enquiry> mockEnquiries = <Enquiry>[
  Enquiry(
    id: 'enq-101',
    studentName: 'Ananya Sharma',
    initial: 'A',
    avatarColor: Color(0xFF5B7CA0),
    course: 'Class 12 Physics',
    timeAgo: '20m ago',
    status: EnquiryStatus.newEnquiry,
    phone: '+91 98765 43210',
    email: 'ananya.sharma@example.com',
    thread: <EnquiryMessage>[
      EnquiryMessage(
        text:
            'Hi, is there a weekend batch for Class 12 Physics? I have school '
            'on weekdays so I can only attend on Saturdays and Sundays.',
        fromOwner: false,
        timeLabel: '20m ago',
      ),
    ],
  ),
  Enquiry(
    id: 'enq-102',
    studentName: 'Rahul Verma',
    initial: 'R',
    avatarColor: Color(0xFFC97373),
    course: 'JEE Crash Course',
    timeAgo: '2h ago',
    status: EnquiryStatus.newEnquiry,
    phone: '+91 91234 56780',
    email: 'rahul.verma@example.com',
    thread: <EnquiryMessage>[
      EnquiryMessage(
        text:
            'What are the fees for the JEE crash course, and when does the next '
            'batch start?',
        fromOwner: false,
        timeLabel: '2h ago',
      ),
    ],
  ),
  Enquiry(
    id: 'enq-103',
    studentName: 'Priya Nair',
    initial: 'P',
    avatarColor: Color(0xFF7C9F7C),
    course: 'NEET Biology',
    timeAgo: 'Yesterday',
    status: EnquiryStatus.replied,
    phone: '+91 99887 76655',
    email: 'priya.nair@example.com',
    thread: <EnquiryMessage>[
      EnquiryMessage(
        text: 'Do you provide study material for NEET biology?',
        fromOwner: false,
        timeLabel: 'Yesterday',
      ),
      EnquiryMessage(
        text:
            'Hi Priya! Yes, every enrolled student gets our full NEET biology '
            'module set plus weekly practice papers. Would you like to visit '
            'for a demo class?',
        fromOwner: true,
        timeLabel: 'Yesterday',
      ),
    ],
  ),
  Enquiry(
    id: 'enq-104',
    studentName: 'Imran Khan',
    initial: 'I',
    avatarColor: Color(0xFF8E7CC3),
    course: 'Class 10 Maths',
    timeAgo: '3 days ago',
    status: EnquiryStatus.replied,
    phone: '+91 90011 22334',
    email: 'imran.khan@example.com',
    thread: <EnquiryMessage>[
      EnquiryMessage(
        text: 'Can my son join the Class 10 Maths batch mid-term?',
        fromOwner: false,
        timeLabel: '3 days ago',
      ),
      EnquiryMessage(
        text:
            'Absolutely - we run catch-up sessions for mid-term joiners. He can '
            'start this week.',
        fromOwner: true,
        timeLabel: '2 days ago',
      ),
    ],
  ),
  Enquiry(
    id: 'enq-105',
    studentName: 'Sneha Gupta',
    initial: 'S',
    avatarColor: Color(0xFFB07D62),
    course: 'Spoken English',
    timeAgo: '1 week ago',
    status: EnquiryStatus.archived,
    phone: '+91 98200 11223',
    email: 'sneha.gupta@example.com',
    thread: <EnquiryMessage>[
      EnquiryMessage(
        text: 'Are the Spoken English classes online or offline?',
        fromOwner: false,
        timeLabel: '1 week ago',
      ),
      EnquiryMessage(
        text: 'They are available in both modes - whichever suits you best.',
        fromOwner: true,
        timeLabel: '6 days ago',
      ),
    ],
  ),
];
