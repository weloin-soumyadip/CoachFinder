/// Models + fixtures + taxonomy backing the owner's manage-center screens until
/// the backend lands.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// One weekday's class hours. A closed day ignores [openAt] / [closeAt].
class DayTiming {
  const DayTiming({
    required this.day,
    required this.isOpen,
    required this.openAt,
    required this.closeAt,
  });

  /// Short day label, e.g. "Mon".
  final String day;

  /// Whether the center runs classes this day.
  final bool isOpen;

  /// Opening time (used only when [isOpen]).
  final TimeOfDay openAt;

  /// Closing time (used only when [isOpen]).
  final TimeOfDay closeAt;

  DayTiming copyWith({bool? isOpen, TimeOfDay? openAt, TimeOfDay? closeAt}) {
    return DayTiming(
      day: day,
      isOpen: isOpen ?? this.isOpen,
      openAt: openAt ?? this.openAt,
      closeAt: closeAt ?? this.closeAt,
    );
  }
}

/// A center photo. Phase 1 has no real images (no image picker in the stack),
/// so each photo is a coloured placeholder tile with a [label].
class CenterPhoto {
  const CenterPhoto({
    required this.id,
    required this.label,
    required this.color,
  });

  final String id;
  final String label;
  final Color color;
}

/// One course offered by the center plus its (pre-formatted) fee.
class CourseFee {
  const CourseFee({required this.id, required this.course, required this.fee});

  final String id;
  final String course;

  /// Pre-formatted fee string, e.g. "₹25,000".
  final String fee;

  CourseFee copyWith({String? course, String? fee}) {
    return CourseFee(
      id: id,
      course: course ?? this.course,
      fee: fee ?? this.fee,
    );
  }
}

/// The coaching center's public listing + management profile.
class CenterProfile {
  const CenterProfile({
    required this.name,
    required this.tagline,
    required this.location,
    required this.address,
    required this.about,
    required this.initial,
    required this.logoColor,
    required this.rating,
    required this.reviewCount,
    required this.profileViews,
    required this.subjects,
    required this.boards,
    required this.timings,
    required this.photos,
    required this.phone,
    required this.email,
    required this.fees,
  });

  final String name;
  final String tagline;
  final String location;
  final String address;
  final String about;

  /// Logo initial + its background colour.
  final String initial;
  final Color logoColor;

  final double rating;
  final int reviewCount;
  final int profileViews;

  final List<String> subjects;
  final List<String> boards;
  final List<DayTiming> timings;
  final List<CenterPhoto> photos;

  final String phone;
  final String email;
  final List<CourseFee> fees;

  CenterProfile copyWith({
    String? name,
    String? tagline,
    String? location,
    String? address,
    String? about,
    List<String>? subjects,
    List<String>? boards,
    List<DayTiming>? timings,
    List<CenterPhoto>? photos,
    String? phone,
    String? email,
    List<CourseFee>? fees,
  }) {
    return CenterProfile(
      name: name ?? this.name,
      tagline: tagline ?? this.tagline,
      location: location ?? this.location,
      address: address ?? this.address,
      about: about ?? this.about,
      initial: initial,
      logoColor: logoColor,
      rating: rating,
      reviewCount: reviewCount,
      profileViews: profileViews,
      subjects: subjects ?? this.subjects,
      boards: boards ?? this.boards,
      timings: timings ?? this.timings,
      photos: photos ?? this.photos,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      fees: fees ?? this.fees,
    );
  }
}

/// Formats a [TimeOfDay] as e.g. "4:00 PM" without needing a localized context.
String formatTimeOfDay(TimeOfDay t) {
  final int hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  final String minute = t.minute.toString().padLeft(2, '0');
  final String period = t.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $period';
}

// ===== TAXONOMY =====

/// Selectable subjects for the subject picker.
const List<String> allSubjects = <String>[
  'Physics',
  'Chemistry',
  'Mathematics',
  'Biology',
  'English',
  'Computer Science',
  'Accountancy',
  'Economics',
];

/// Selectable boards/curricula for the board picker.
const List<String> allBoards = <String>[
  'CBSE',
  'ICSE',
  'State Board',
  'IB',
  'IGCSE',
];

// ===== FIXTURE =====

/// The owner's seeded center. The name + headline figures match the dashboard
/// and owner profile so the owner experience reads as one consistent business.
final CenterProfile mockCenter = CenterProfile(
  name: 'Apex Coaching Centre',
  tagline: 'Excellence in Science & Maths since 2012',
  location: 'Salt Lake, Kolkata',
  address: 'BD-12, Sector 1, Salt Lake City, Kolkata 700064',
  about:
      'Apex Coaching Centre has guided students through board and competitive '
      'exams for over a decade. Our small-batch classes, experienced faculty, '
      'and regular mock tests help students build genuine understanding and '
      'exam confidence.',
  initial: 'A',
  logoColor: AppColors.ownerAccent,
  rating: 4.8,
  reviewCount: 128,
  profileViews: 1248,
  subjects: <String>['Physics', 'Chemistry', 'Mathematics', 'Biology'],
  boards: <String>['CBSE', 'ICSE'],
  timings: const <DayTiming>[
    DayTiming(
      day: 'Mon',
      isOpen: true,
      openAt: TimeOfDay(hour: 16, minute: 0),
      closeAt: TimeOfDay(hour: 19, minute: 0),
    ),
    DayTiming(
      day: 'Tue',
      isOpen: true,
      openAt: TimeOfDay(hour: 16, minute: 0),
      closeAt: TimeOfDay(hour: 19, minute: 0),
    ),
    DayTiming(
      day: 'Wed',
      isOpen: true,
      openAt: TimeOfDay(hour: 16, minute: 0),
      closeAt: TimeOfDay(hour: 19, minute: 0),
    ),
    DayTiming(
      day: 'Thu',
      isOpen: true,
      openAt: TimeOfDay(hour: 16, minute: 0),
      closeAt: TimeOfDay(hour: 19, minute: 0),
    ),
    DayTiming(
      day: 'Fri',
      isOpen: true,
      openAt: TimeOfDay(hour: 16, minute: 0),
      closeAt: TimeOfDay(hour: 19, minute: 0),
    ),
    DayTiming(
      day: 'Sat',
      isOpen: true,
      openAt: TimeOfDay(hour: 10, minute: 0),
      closeAt: TimeOfDay(hour: 13, minute: 0),
    ),
    DayTiming(
      day: 'Sun',
      isOpen: false,
      openAt: TimeOfDay(hour: 10, minute: 0),
      closeAt: TimeOfDay(hour: 13, minute: 0),
    ),
  ],
  photos: const <CenterPhoto>[
    CenterPhoto(id: 'ph-1', label: 'Classroom', color: Color(0xFF5B7CA0)),
    CenterPhoto(id: 'ph-2', label: 'Lab', color: Color(0xFF7C9F7C)),
    CenterPhoto(id: 'ph-3', label: 'Library', color: Color(0xFFC9A26B)),
    CenterPhoto(id: 'ph-4', label: 'Reception', color: Color(0xFF8E7CC3)),
  ],
  phone: '+91 98300 12345',
  email: 'hello@apexcoaching.com',
  fees: const <CourseFee>[
    CourseFee(id: 'fee-1', course: 'Class 12 Physics', fee: '₹18,000'),
    CourseFee(id: 'fee-2', course: 'JEE Crash Course', fee: '₹25,000'),
    CourseFee(id: 'fee-3', course: 'NEET Biology', fee: '₹22,000'),
  ],
);
