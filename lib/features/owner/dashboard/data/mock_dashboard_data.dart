/// Fixture data + view models backing the owner Dashboard screen until the
/// real backend lands.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

/// Direction of a stat's period-over-period change, controlling the caption
/// colour and arrow on a [DashboardStat] card.
enum StatTrend { up, down, neutral }

/// One headline metric rendered as a stat card on the dashboard.
class DashboardStat {
  const DashboardStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    this.caption,
    this.trend = StatTrend.neutral,
  });

  /// Human label, e.g. "Profile Views".
  final String label;

  /// Pre-formatted display value, e.g. "1,248" or "4.8".
  final String value;

  /// Leading glyph shown in a tinted circle.
  final IconData icon;

  /// Accent colour for the icon + its tint background. A fixed brand/semantic
  /// token - legible in both themes since it is used as a foreground over a
  /// low-alpha tint of itself.
  final Color accent;

  /// Optional small caption beneath the label, e.g. "+12%" or "128 reviews".
  final String? caption;

  /// Whether [caption] reads as a positive, negative, or neutral change.
  final StatTrend trend;
}

/// One day's profile-view count in the 7-day mini chart.
class DailyViews {
  const DailyViews({required this.label, required this.views});

  /// Short day label, e.g. "Mon".
  final String label;

  /// View count for that day.
  final int views;
}

/// A condensed enquiry shown in the dashboard's "Recent Enquiries" preview.
class EnquiryPreview {
  const EnquiryPreview({
    required this.id,
    required this.studentName,
    required this.message,
    required this.timeAgo,
    required this.initial,
    required this.avatarColor,
    this.isNew = false,
  });

  /// Stable id, forwarded to the enquiry-detail route on tap.
  final String id;

  /// Sender's display name.
  final String studentName;

  /// Short snippet of the enquiry body.
  final String message;

  /// Pre-formatted relative time, e.g. "2h ago".
  final String timeAgo;

  /// Avatar initial.
  final String initial;

  /// Avatar background colour (fixture content colour).
  final Color avatarColor;

  /// Whether the enquiry is unread / awaiting a first reply.
  final bool isNew;
}

// ===== FIXTURES =====

/// The four headline metrics shown at the top of the dashboard.
const List<DashboardStat> mockDashboardStats = <DashboardStat>[
  DashboardStat(
    label: AppStrings.dashboardStatProfileViews,
    value: '1,248',
    icon: Icons.visibility_outlined,
    accent: AppColors.ownerAccent,
    caption: '+12%',
    trend: StatTrend.up,
  ),
  DashboardStat(
    label: AppStrings.dashboardStatNewEnquiries,
    value: '8',
    icon: Icons.mark_email_unread_outlined,
    accent: AppColors.info,
    caption: '+3 today',
    trend: StatTrend.up,
  ),
  DashboardStat(
    label: AppStrings.dashboardStatRating,
    value: '4.8',
    icon: Icons.star_outline,
    accent: AppColors.ratingStar,
    caption: '128 reviews',
  ),
  DashboardStat(
    label: AppStrings.dashboardStatActiveStudents,
    value: '156',
    icon: Icons.people_outline,
    accent: AppColors.success,
    caption: '+5 this month',
    trend: StatTrend.up,
  ),
];

/// Profile views per day over the last week. The total (1,248) matches the
/// "Profile Views" stat above.
const List<DailyViews> mockWeeklyViews = <DailyViews>[
  DailyViews(label: 'Mon', views: 142),
  DailyViews(label: 'Tue', views: 168),
  DailyViews(label: 'Wed', views: 121),
  DailyViews(label: 'Thu', views: 205),
  DailyViews(label: 'Fri', views: 233),
  DailyViews(label: 'Sat', views: 198),
  DailyViews(label: 'Sun', views: 181),
];

/// The latest enquiries surfaced in the dashboard preview list.
const List<EnquiryPreview> mockRecentEnquiries = <EnquiryPreview>[
  EnquiryPreview(
    id: 'enq-101',
    studentName: 'Ananya Sharma',
    message: 'Is there a weekend batch for Class 12 Physics?',
    timeAgo: '20m ago',
    initial: 'A',
    avatarColor: Color(0xFF5B7CA0),
    isNew: true,
  ),
  EnquiryPreview(
    id: 'enq-102',
    studentName: 'Rahul Verma',
    message: 'What are the fees for the JEE crash course?',
    timeAgo: '2h ago',
    initial: 'R',
    avatarColor: Color(0xFFC97373),
    isNew: true,
  ),
  EnquiryPreview(
    id: 'enq-103',
    studentName: 'Priya Nair',
    message: 'Do you provide study material for NEET biology?',
    timeAgo: 'Yesterday',
    initial: 'P',
    avatarColor: Color(0xFF7C9F7C),
  ),
];
