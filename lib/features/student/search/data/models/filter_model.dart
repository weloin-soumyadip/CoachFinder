/// Active search filter state and its serialization to query parameters.
library;

/// Education board the backend accepts for teacher/center search. The
/// [wireValue] is the exact string the API's `board` enum expects.
enum SearchBoard {
  /// Central Board of Secondary Education.
  cbse,

  /// Indian Certificate of Secondary Education.
  icse,

  /// State board.
  state,

  /// International Baccalaureate.
  ib,

  /// International General Certificate of Secondary Education.
  igcse,

  /// Any other board.
  other;

  /// The exact backend enum string for this board.
  String get wireValue {
    switch (this) {
      case SearchBoard.cbse:
        return 'CBSE';
      case SearchBoard.icse:
        return 'ICSE';
      case SearchBoard.state:
        return 'State';
      case SearchBoard.ib:
        return 'IB';
      case SearchBoard.igcse:
        return 'IGCSE';
      case SearchBoard.other:
        return 'Other';
    }
  }
}

/// Immutable snapshot of the filters a student has applied. Serializes to the
/// query-parameter map the search endpoint expects via [toQueryParameters].
/// Geo filtering is intentionally unsupported (no device location), so no
/// lat/lng/distance fields exist here.
class SearchFilters {
  const SearchFilters({
    this.q,
    this.subject,
    this.city,
    this.board,
    this.minRating,
    this.minFees,
    this.maxFees,
  });

  /// Free-text keyword (`name`/`bio`/`description`, or `title` for webinars).
  final String? q;

  /// Subject name, slug, or id — resolved server-side.
  final String? subject;

  /// City exact match.
  final String? city;

  /// Education board filter.
  final SearchBoard? board;

  /// Minimum average rating (0..5).
  final double? minRating;

  /// Minimum fees bound.
  final int? minFees;

  /// Maximum fees bound.
  final int? maxFees;

  /// True when no filter (including [q]) is set.
  bool get isEmpty =>
      (q == null || q!.isEmpty) &&
      (subject == null || subject!.isEmpty) &&
      (city == null || city!.isEmpty) &&
      board == null &&
      minRating == null &&
      minFees == null &&
      maxFees == null;

  /// True when any refinement *other than* the free-text query [q] is set.
  /// Drives the "Clear filters" affordance on the results screen.
  bool get hasActiveFilters =>
      (subject != null && subject!.isNotEmpty) ||
      (city != null && city!.isNotEmpty) ||
      board != null ||
      minRating != null ||
      minFees != null ||
      maxFees != null;

  /// Field-wise copy. Each named argument replaces the existing value when
  /// supplied (pass `null` defaults keep the current value — to clear a field
  /// build a fresh [SearchFilters]).
  SearchFilters copyWith({
    String? q,
    String? subject,
    String? city,
    SearchBoard? board,
    double? minRating,
    int? minFees,
    int? maxFees,
  }) {
    return SearchFilters(
      q: q ?? this.q,
      subject: subject ?? this.subject,
      city: city ?? this.city,
      board: board ?? this.board,
      minRating: minRating ?? this.minRating,
      minFees: minFees ?? this.minFees,
      maxFees: maxFees ?? this.maxFees,
    );
  }

  /// Builds the query-parameter map for one search call, omitting any
  /// null/empty entry.
  ///
  /// When [forWebinar] is true the result includes ONLY `q` — the webinar
  /// schema is `.strict()` and rejects `subject`/`city`/`board`/`minRating`/
  /// `minFees`/`maxFees` with a 400. For teacher/coaching every set field is
  /// included; [board] is serialized via its [SearchBoard.wireValue].
  Map<String, dynamic> toQueryParameters({required bool forWebinar}) {
    final Map<String, dynamic> params = <String, dynamic>{};
    if (q != null && q!.isNotEmpty) params['q'] = q;
    if (forWebinar) return params;

    if (subject != null && subject!.isNotEmpty) params['subject'] = subject;
    if (city != null && city!.isNotEmpty) params['city'] = city;
    if (board != null) params['board'] = board!.wireValue;
    if (minRating != null) params['minRating'] = minRating;
    if (minFees != null) params['minFees'] = minFees;
    if (maxFees != null) params['maxFees'] = maxFees;
    return params;
  }
}
