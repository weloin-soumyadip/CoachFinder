/// Dio calls for the unified search endpoint, parsing the `data` + sibling
/// `pagination` blocks the standard [ApiResponse] would drop.
library;

import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_config.dart';
import '../models/filter_model.dart';
import '../models/search_result_model.dart';

/// One page of search results of type [T] plus its pagination metadata.
class SearchPage<T> {
  const SearchPage({required this.items, required this.pagination});

  /// The parsed `data[]` items for this page.
  final List<T> items;

  /// The `pagination` sibling block.
  final SearchPagination pagination;
}

/// Thin remote datasource for the student search feature. Each method issues
/// exactly one `GET /api/search` call (with the right `searchType`) via
/// [ApiClient.rawGet], then reads `data` + `pagination` off the raw envelope.
/// No business logic — the repository owns that. The interceptor attaches the
/// bearer token (search is student-only and protected).
class SearchRemoteDataSource {
  SearchRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// `GET /api/search?searchType=teacher` with the teacher/coaching param set.
  Future<SearchPage<TeacherSearchResult>> searchTeachers(
    SearchFilters filters, {
    required int page,
    required int limit,
  }) async {
    final response = await _apiClient.rawGet(
      ApiConfig.search,
      queryParameters: <String, dynamic>{
        'searchType': 'teacher',
        'page': page,
        'limit': limit,
        ...filters.toQueryParameters(forWebinar: false),
      },
    );
    return _parsePage(
      response.data,
      (Map<String, dynamic> j) => TeacherSearchResult.fromJson(j),
    );
  }

  /// `GET /api/search?searchType=coaching` with the teacher/coaching param set.
  Future<SearchPage<CenterSearchResult>> searchCenters(
    SearchFilters filters, {
    required int page,
    required int limit,
  }) async {
    final response = await _apiClient.rawGet(
      ApiConfig.search,
      queryParameters: <String, dynamic>{
        'searchType': 'coaching',
        'page': page,
        'limit': limit,
        ...filters.toQueryParameters(forWebinar: false),
      },
    );
    return _parsePage(
      response.data,
      (Map<String, dynamic> j) => CenterSearchResult.fromJson(j),
    );
  }

  /// `GET /api/search?searchType=webinar` with the REDUCED webinar param set
  /// (only `q` — the webinar schema is strict and 400s on the other filters).
  Future<SearchPage<WebinarSearchResult>> searchWebinars(
    SearchFilters filters, {
    required int page,
    required int limit,
  }) async {
    final response = await _apiClient.rawGet(
      ApiConfig.search,
      queryParameters: <String, dynamic>{
        'searchType': 'webinar',
        'page': page,
        'limit': limit,
        ...filters.toQueryParameters(forWebinar: true),
      },
    );
    return _parsePage(
      response.data,
      (Map<String, dynamic> j) => WebinarSearchResult.fromJson(j),
    );
  }

  /// Extracts `data` (a list) and `pagination` (a sibling map) from a raw
  /// search envelope, mapping each element with [fromJson].
  SearchPage<T> _parsePage<T>(
    Map<String, dynamic>? body,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final Map<String, dynamic> json = body ?? <String, dynamic>{};
    final dynamic rawData = json['data'];
    final List<T> items = rawData is List
        ? rawData.whereType<Map<String, dynamic>>().map(fromJson).toList()
        : <T>[];
    return SearchPage<T>(
      items: items,
      pagination: SearchPagination.fromJson(
          json['pagination'] as Map<String, dynamic>?),
    );
  }
}
