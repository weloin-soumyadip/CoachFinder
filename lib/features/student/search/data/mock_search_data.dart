/// Fixture data backing the student Search screen until the real backend lands.
library;

import 'package:flutter/material.dart';

/// Which kind of result the segmented control is filtering to.
enum SearchEntityType { all, teachers, institutes }

/// A teacher / coach surfaced in search results.
class SearchTeacher {
  const SearchTeacher({
    required this.id,
    required this.name,
    required this.title,
    required this.rating,
    required this.sessionPrice,
    required this.initial,
    required this.avatarColor,
    required this.online,
    required this.tags,
  });

  final String id;
  final String name;
  final String title;
  final double rating;
  final int sessionPrice;
  final String initial;
  final Color avatarColor;

  /// Whether to show the green "available" dot on the avatar.
  final bool online;
  final List<String> tags;
}

/// A coaching institute / center surfaced in search results.
class SearchInstitute {
  const SearchInstitute({
    required this.id,
    required this.name,
    required this.location,
    required this.rating,
    required this.courseCount,
    required this.initial,
    required this.logoColor,
    required this.tags,
  });

  final String id;
  final String name;
  final String location;
  final double rating;
  final int courseCount;
  final String initial;
  final Color logoColor;
  final List<String> tags;
}

// ===== FIXTURES =====

final List<SearchTeacher> mockSearchTeachers = <SearchTeacher>[
  const SearchTeacher(
    id: 'sarah-chen',
    name: 'Dr. Sarah Chen',
    title: 'Executive Leadership Coach',
    rating: 4.9,
    sessionPrice: 120,
    initial: 'S',
    avatarColor: Color(0xFF5B7CA0),
    online: true,
    tags: <String>['Leadership', 'Communication', 'EQ'],
  ),
  const SearchTeacher(
    id: 'marcus-thorne',
    name: 'Marcus Thorne',
    title: 'Senior Tech Architect & Mentor',
    rating: 4.8,
    sessionPrice: 95,
    initial: 'M',
    avatarColor: Color(0xFF6B5E8C),
    online: false,
    tags: <String>['Tech Stack', 'Architecture'],
  ),
  const SearchTeacher(
    id: 'elena-rodriguez',
    name: 'Elena Rodriguez',
    title: 'Wellness & Career Balance',
    rating: 5.0,
    sessionPrice: 110,
    initial: 'E',
    avatarColor: Color(0xFFC97373),
    online: true,
    tags: <String>['Mindfulness', 'Burnout'],
  ),
  const SearchTeacher(
    id: 'david-okafor',
    name: 'David Okafor',
    title: 'Public Speaking & Storytelling',
    rating: 4.7,
    sessionPrice: 80,
    initial: 'D',
    avatarColor: Color(0xFF7C9F7C),
    online: false,
    tags: <String>['Voice', 'Confidence'],
  ),
  const SearchTeacher(
    id: 'aisha-khan',
    name: 'Aisha Khan',
    title: 'Data Science Mentor',
    rating: 4.9,
    sessionPrice: 100,
    initial: 'A',
    avatarColor: Color(0xFF4F8C8C),
    online: true,
    tags: <String>['Python', 'Machine Learning'],
  ),
];

final List<SearchInstitute> mockSearchInstitutes = <SearchInstitute>[
  const SearchInstitute(
    id: 'brightpath-academy',
    name: 'BrightPath Academy',
    location: 'Bengaluru',
    rating: 4.7,
    courseCount: 24,
    initial: 'B',
    logoColor: Color(0xFF1A56DB),
    tags: <String>['Career', 'Test Prep'],
  ),
  const SearchInstitute(
    id: 'summit-coaching',
    name: 'Summit Coaching Institute',
    location: 'Mumbai',
    rating: 4.6,
    courseCount: 18,
    initial: 'S',
    logoColor: Color(0xFFE05A2B),
    tags: <String>['Leadership', 'Business'],
  ),
  const SearchInstitute(
    id: 'zenith-learning',
    name: 'Zenith Learning Center',
    location: 'New Delhi',
    rating: 4.8,
    courseCount: 32,
    initial: 'Z',
    logoColor: Color(0xFF0D9488),
    tags: <String>['Tech', 'Data Science'],
  ),
  const SearchInstitute(
    id: 'harmony-wellness',
    name: 'Harmony Wellness Studio',
    location: 'Pune',
    rating: 4.9,
    courseCount: 12,
    initial: 'H',
    logoColor: Color(0xFF7C3AED),
    tags: <String>['Wellness', 'Mindfulness'],
  ),
];

/// Category chips shown in the resting (pre-search) state.
const List<String> mockSearchCategories = <String>[
  'Career',
  'Wellness',
  'Tech',
  'Leadership',
  'Communication',
  'Test Prep',
  'Business',
  'Data Science',
];

/// Recent search terms shown in the resting (pre-search) state.
const List<String> mockRecentSearches = <String>[
  'Leadership coach',
  'IELTS preparation',
  'Data science mentor',
  'Public speaking',
];
