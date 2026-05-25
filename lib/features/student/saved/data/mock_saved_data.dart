/// Fixture data backing the student Saved screen until the real backend lands.
library;

import 'package:flutter/material.dart';

import '../../search/data/mock_search_data.dart';

/// Which kind of saved item the filter is narrowing to. "Coachings" maps to
/// institutes / centers and "Tutors" maps to teachers.
enum SavedFilter { all, coachings, tutors }

/// Tutors the student has bookmarked. Reuses the Search [SearchTeacher] model
/// so the existing result card can render them unchanged.
final List<SearchTeacher> mockSavedTutors = <SearchTeacher>[
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
];

/// Coaching institutes / centers the student has bookmarked. Reuses the Search
/// [SearchInstitute] model so the existing result card can render them.
final List<SearchInstitute> mockSavedCoachings = <SearchInstitute>[
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
    id: 'brightpath-academy',
    name: 'BrightPath Academy',
    location: 'Bengaluru',
    rating: 4.7,
    courseCount: 24,
    initial: 'B',
    logoColor: Color(0xFF1A56DB),
    tags: <String>['Career', 'Test Prep'],
  ),
];
