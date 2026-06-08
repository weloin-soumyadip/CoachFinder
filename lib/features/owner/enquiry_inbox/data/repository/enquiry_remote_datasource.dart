/// Dio calls for the owner enquiry list / search / detail / update endpoints.
library;

import '../../../../../core/api/api_client.dart';
import '../../../../../core/api/api_config.dart';
import '../models/enquiry_model.dart';

/// One raw page of enquiry docs plus its pagination numbers.
typedef EnquiryRawPage = ({
  List<Map<String, dynamic>> rows,
  int page,
  int pages,
  int total,
});

/// Thin remote datasource for the owner enquiries feature.
class EnquiryRemoteDataSource {
  /// Wraps the shared [ApiClient].
  EnquiryRemoteDataSource(this._apiClient);

  final ApiClient _apiClient;

  /// `GET /api/owners/enquiries` — paginated, optional status filter.
  Future<EnquiryRawPage> list({
    required int page,
    required int limit,
    EnquiryStatus? status,
  }) async {
    final response = await _apiClient.rawGet(
      ApiConfig.ownersEnquiries,
      queryParameters: <String, dynamic>{
        'page': page,
        'limit': limit,
        if (status != null) 'status': status.wireValue,
      },
    );
    return _parsePage(response.data);
  }

  /// `GET /api/owners/enquiries/search` — keyword search (+ optional status).
  Future<EnquiryRawPage> search({
    required int page,
    required int limit,
    required String query,
    EnquiryStatus? status,
  }) async {
    final response = await _apiClient.rawGet(
      ApiConfig.ownersEnquiriesSearch,
      queryParameters: <String, dynamic>{
        'page': page,
        'limit': limit,
        'q': query,
        if (status != null) 'status': status.wireValue,
      },
    );
    return _parsePage(response.data);
  }

  /// `GET /api/owners/enquiries/:id` — one enquiry (`{enquiry}`).
  Future<Map<String, dynamic>> fetchById(String id) async {
    final response = await _apiClient.rawGet(ApiConfig.ownerEnquiryById(id));
    final Map<String, dynamic> body = response.data ?? <String, dynamic>{};
    return (body['enquiry'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  /// `PATCH /api/owners/enquiries/:id` — update `{status?, ownerNotes?}`.
  Future<Map<String, dynamic>> update(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response =
        await _apiClient.rawPatch(ApiConfig.ownerEnquiryById(id), data: body);
    final Map<String, dynamic> data = response.data ?? <String, dynamic>{};
    return (data['enquiry'] as Map<String, dynamic>?) ?? <String, dynamic>{};
  }

  /// Reads `{data:[…], pagination:{page,pages,total}}`, coercing pagination
  /// numbers (these endpoints can echo them back as strings).
  EnquiryRawPage _parsePage(Map<String, dynamic>? body) {
    final Map<String, dynamic> map = body ?? <String, dynamic>{};
    final List<Map<String, dynamic>> rows =
        ((map['data'] as List<dynamic>?) ?? <dynamic>[])
            .whereType<Map<String, dynamic>>()
            .toList();
    final Map<String, dynamic> pag =
        (map['pagination'] as Map<String, dynamic>?) ?? <String, dynamic>{};
    return (
      rows: rows,
      page: _asInt(pag['page'], 1),
      pages: _asInt(pag['pages'], 1),
      total: _asInt(pag['total'], rows.length),
    );
  }

  static int _asInt(dynamic value, int fallback) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }
}
