/// Aggregate payload for the student dashboard endpoint.
library;

import 'top_center_model.dart';
import 'top_teacher_model.dart';
import 'upcoming_webinar_model.dart';

/// The aggregated landing data returned by `GET /api/students/dashboard`.
///
/// Envelope nuance: the backend nests the payload under a top-level
/// `dashboard` key (`{success, dashboard: {...}}`), NOT under `data`. Since
/// [ApiResponse.fromJson] does `json['data'] ?? json`, it hands this
/// [fromJson] the FULL top-level map — so [fromJson] reads `json['dashboard']`
/// itself, tolerating it being absent or null.
class StudentDashboard {
  const StudentDashboard({
    required this.topTeachers,
    required this.topCenters,
    required this.upcomingWebinars,
  });

  /// Top-rated teachers (up to 5).
  final List<TopTeacher> topTeachers;

  /// Top-rated coaching centers (up to 3).
  final List<TopCenter> topCenters;

  /// Webinars scheduled within the next two days (up to 3).
  final List<UpcomingWebinar> upcomingWebinars;

  /// True when every section is empty (used by the screen for empty-state UI).
  bool get isEmpty =>
      topTeachers.isEmpty && topCenters.isEmpty && upcomingWebinars.isEmpty;

  /// Parses the full top-level envelope, reading the nested `dashboard` map.
  factory StudentDashboard.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> dashboard =
        (json['dashboard'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return StudentDashboard(
      topTeachers: (dashboard['topTeachers'] as List<dynamic>?)
              ?.map(
                  (dynamic e) => TopTeacher.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <TopTeacher>[],
      topCenters: (dashboard['topCenters'] as List<dynamic>?)
              ?.map(
                  (dynamic e) => TopCenter.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <TopCenter>[],
      upcomingWebinars: (dashboard['upcomingWebinars'] as List<dynamic>?)
              ?.map((dynamic e) =>
                  UpcomingWebinar.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <UpcomingWebinar>[],
    );
  }
}
