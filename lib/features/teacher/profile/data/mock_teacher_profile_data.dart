/// Models + fixture + taxonomy backing the teacher profile screens until the
/// backend lands.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The teacher's public listing + account profile.
///
/// A teacher is a hybrid: an independent tutor and/or affiliated with a center
/// ([isIndependent] + [affiliation]). The listing fields are what students see
/// when discovering the tutor; the headline figures ([rating], [profileViews],
/// etc.) are read-only metrics.
class TeacherProfile {
  const TeacherProfile({
    required this.name,
    required this.headline,
    required this.initial,
    required this.avatarColor,
    required this.email,
    required this.isIndependent,
    required this.affiliation,
    required this.rating,
    required this.reviewCount,
    required this.profileViews,
    required this.studentsTaught,
    required this.responseRatePercent,
    required this.subjects,
    required this.expertise,
    required this.bio,
    required this.hourlyRate,
    required this.experienceYears,
  });

  final String name;

  /// Title shown under the name, e.g. "Physics & Maths Tutor".
  final String headline;

  final String initial;
  final Color avatarColor;

  /// Account email (account header / contact).
  final String email;

  /// Whether the tutor works independently. When false, [affiliation] names the
  /// center they teach at.
  final bool isIndependent;
  final String affiliation;

  final double rating;
  final int reviewCount;
  final int profileViews;
  final int studentsTaught;
  final int responseRatePercent;

  /// Subjects taught (tag chips).
  final List<String> subjects;

  /// One-line specialization, e.g. "JEE & NEET physics, board exam prep".
  final String expertise;

  /// Public "About me" write-up.
  final String bio;

  /// Hourly rate in rupees.
  final int hourlyRate;

  /// Years of teaching experience.
  final int experienceYears;

  TeacherProfile copyWith({
    String? name,
    String? headline,
    String? email,
    bool? isIndependent,
    String? affiliation,
    List<String>? subjects,
    String? expertise,
    String? bio,
    int? hourlyRate,
    int? experienceYears,
  }) {
    return TeacherProfile(
      name: name ?? this.name,
      headline: headline ?? this.headline,
      initial: initial,
      avatarColor: avatarColor,
      email: email ?? this.email,
      isIndependent: isIndependent ?? this.isIndependent,
      affiliation: affiliation ?? this.affiliation,
      rating: rating,
      reviewCount: reviewCount,
      profileViews: profileViews,
      studentsTaught: studentsTaught,
      responseRatePercent: responseRatePercent,
      subjects: subjects ?? this.subjects,
      expertise: expertise ?? this.expertise,
      bio: bio ?? this.bio,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      experienceYears: experienceYears ?? this.experienceYears,
    );
  }
}

/// Selectable subjects for the teacher's subject picker.
const List<String> teacherSubjectOptions = <String>[
  'Physics',
  'Chemistry',
  'Mathematics',
  'Biology',
  'English',
  'Computer Science',
  'Economics',
];

/// The signed-in teacher. Fixture-backed until the backend lands.
const TeacherProfile mockTeacherProfile = TeacherProfile(
  name: 'Vikram Desai',
  headline: 'Physics & Maths Tutor',
  initial: 'V',
  avatarColor: AppColors.teacherAccent,
  email: 'vikram.desai@example.com',
  isIndependent: true,
  affiliation: '',
  rating: 4.9,
  reviewCount: 96,
  profileViews: 842,
  studentsTaught: 240,
  responseRatePercent: 98,
  subjects: <String>['Physics', 'Mathematics'],
  expertise: 'JEE & NEET physics, CBSE/ICSE board exam preparation',
  bio:
      'I help Class 11-12 students build deep conceptual clarity in Physics and '
      'Mathematics. With small online batches and weekly problem-solving '
      'sessions, my students consistently improve their board and entrance-exam '
      'scores.',
  hourlyRate: 800,
  experienceYears: 8,
);
