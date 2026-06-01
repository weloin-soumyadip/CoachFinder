/// Models + fixtures backing the teacher search (find a coaching center to
/// affiliate with) until the backend lands.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A coaching center the teacher can request to affiliate with.
class AffiliationCenter {
  const AffiliationCenter({
    required this.id,
    required this.name,
    required this.location,
    required this.initial,
    required this.logoColor,
    required this.rating,
    required this.subjects,
    required this.isHiring,
  });

  final String id;
  final String name;

  /// City · area, e.g. "Mumbai · Andheri".
  final String location;

  /// Single-letter logo initial.
  final String initial;

  /// Logo tile background colour.
  final Color logoColor;

  final double rating;

  /// Subjects the center teaches (tag chips).
  final List<String> subjects;

  /// Whether the center is actively looking for tutors.
  final bool isHiring;
}

/// Coaching centers open to (or discoverable by) tutors. Fixture-backed until
/// the backend lands; resets on restart.
final List<AffiliationCenter> mockAffiliationCenters = <AffiliationCenter>[
  const AffiliationCenter(
    id: 'ctr-1',
    name: 'Apex Classes',
    location: 'Mumbai · Andheri',
    initial: 'A',
    logoColor: AppColors.studentPrimary,
    rating: 4.8,
    subjects: <String>['Physics', 'Mathematics'],
    isHiring: true,
  ),
  const AffiliationCenter(
    id: 'ctr-2',
    name: 'Brilliant Tutorials',
    location: 'Pune · Kothrud',
    initial: 'B',
    logoColor: AppColors.ownerAccent,
    rating: 4.6,
    subjects: <String>['Chemistry', 'Biology'],
    isHiring: true,
  ),
  const AffiliationCenter(
    id: 'ctr-3',
    name: 'Cerebral Academy',
    location: 'Mumbai · Dadar',
    initial: 'C',
    logoColor: AppColors.teacherAccent,
    rating: 4.9,
    subjects: <String>['Physics', 'Mathematics', 'Chemistry'],
    isHiring: false,
  ),
  const AffiliationCenter(
    id: 'ctr-4',
    name: 'Disha Coaching',
    location: 'Thane · Ghodbunder',
    initial: 'D',
    logoColor: AppColors.info,
    rating: 4.4,
    subjects: <String>['Mathematics', 'Economics'],
    isHiring: true,
  ),
  const AffiliationCenter(
    id: 'ctr-5',
    name: 'EduPoint Institute',
    location: 'Navi Mumbai · Vashi',
    initial: 'E',
    logoColor: AppColors.success,
    rating: 4.7,
    subjects: <String>['Biology', 'Chemistry', 'English'],
    isHiring: false,
  ),
  const AffiliationCenter(
    id: 'ctr-6',
    name: 'Foundation Hub',
    location: 'Pune · Viman Nagar',
    initial: 'F',
    logoColor: AppColors.warning,
    rating: 4.5,
    subjects: <String>['Physics', 'Computer Science'],
    isHiring: true,
  ),
];

/// Recent center searches shown in the resting state. Static fixture.
const List<String> mockTeacherSearchRecents = <String>[
  'JEE physics centers',
  'Andheri coaching',
  'Hiring chemistry tutors',
];
