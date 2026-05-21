/// Fixture data backing the student Home screen until the real backend lands.
library;

import 'package:flutter/material.dart';

/// Minimal model of the signed-in student. Real model lands when the backend
/// contract is finalised.
class MockUser {
  const MockUser({required this.firstName, required this.fullName});

  final String firstName;
  final String fullName;
}

/// Coach surfaced in the "Recommended For You" list.
class Coach {
  const Coach({
    required this.id,
    required this.name,
    required this.role,
    required this.rating,
    required this.hourlyRate,
    required this.initial,
    required this.avatarColor,
    required this.tags,
  });

  final String id;
  final String name;
  final String role;
  final double rating;
  final int hourlyRate;
  final String initial;
  final Color avatarColor;
  final List<CoachTag> tags;
}

/// Coloured pill that hangs off a coach card (e.g. "BUSINESS", "MINDSET").
class CoachTag {
  const CoachTag({required this.label, required this.background});

  final String label;
  final Color background;
}

/// One entry in the horizontally-scrolling "Trending Topics" rail.
class TrendingTopic {
  const TrendingTopic({
    required this.id,
    required this.label,
    required this.icon,
    required this.background,
    required this.iconColor,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color background;
  final Color iconColor;
}

/// The featured "Next Session" CTA card at the top of the Home screen.
class NextSession {
  const NextSession({
    required this.title,
    required this.coachName,
    required this.durationMinutes,
    required this.displayTime,
  });

  final String title;
  final String coachName;
  final int durationMinutes;

  /// Pre-formatted time string for now (e.g. `'16:00 PM'`). The real backend
  /// will return a DateTime which we format at the call site.
  final String displayTime;
}

/// The "Personalized Path" card near the bottom of the Home feed.
class PersonalizedPath {
  const PersonalizedPath({
    required this.title,
    required this.progressPercent,
  });

  final String title;

  /// Integer percentage 0..100.
  final int progressPercent;
}

// ===== FIXTURES =====

const MockUser mockUser = MockUser(
  firstName: 'Sarah',
  fullName: 'Sarah Johnson',
);

const NextSession mockNextSession = NextSession(
  title: 'Leadership Strategy',
  coachName: 'Coach Alex Rivera',
  durationMinutes: 30,
  displayTime: '16:00 PM',
);

final List<TrendingTopic> mockTopics = <TrendingTopic>[
  const TrendingTopic(
    id: 'mindfulness',
    label: 'Mindfulness',
    icon: Icons.eco_outlined,
    background: Color(0xFFA8E0BD),
    iconColor: Color(0xFF1B7A4B),
  ),
  const TrendingTopic(
    id: 'career-growth',
    label: 'Career Growth',
    icon: Icons.trending_up,
    background: Color(0xFFE3DFCF),
    iconColor: Color(0xFF6B5E3C),
  ),
  const TrendingTopic(
    id: 'leadership',
    label: 'Leadership',
    icon: Icons.workspace_premium_outlined,
    background: Color(0xFFD5DEFC),
    iconColor: Color(0xFF2A4D9F),
  ),
  const TrendingTopic(
    id: 'communication',
    label: 'Communication',
    icon: Icons.forum_outlined,
    background: Color(0xFFFFD8C2),
    iconColor: Color(0xFF8B4513),
  ),
];

final List<Coach> mockCoaches = <Coach>[
  const Coach(
    id: 'marcus-chen',
    name: 'Marcus Chen',
    role: 'Executive Leadership',
    rating: 4.9,
    hourlyRate: 85,
    initial: 'M',
    avatarColor: Color(0xFF5B7CA0),
    tags: <CoachTag>[
      CoachTag(label: 'BUSINESS', background: Color(0xFF7BCE9B)),
      CoachTag(label: 'STRATEGY', background: Color(0xFFB6E8C8)),
    ],
  ),
  const Coach(
    id: 'elena-rodriguez',
    name: 'Elena Rodriguez',
    role: 'Wellness & Life Balance',
    rating: 4.8,
    hourlyRate: 60,
    initial: 'E',
    avatarColor: Color(0xFFC97373),
    tags: <CoachTag>[
      CoachTag(label: 'MINDSET', background: Color(0xFFFFC9A8)),
      CoachTag(label: 'HEALTH', background: Color(0xFFB6E8C8)),
    ],
  ),
  const Coach(
    id: 'david-miller',
    name: 'David Miller',
    role: 'Public Speaking Mastery',
    rating: 5.0,
    hourlyRate: 120,
    initial: 'D',
    avatarColor: Color(0xFF7C9F7C),
    tags: <CoachTag>[
      CoachTag(label: 'VOICE', background: Color(0xFFE0CFFA)),
      CoachTag(label: 'IMPACT', background: Color(0xFFB6E8C8)),
    ],
  ),
];

const PersonalizedPath mockPath = PersonalizedPath(
  title: 'Public Speaking 101',
  progressPercent: 75,
);
