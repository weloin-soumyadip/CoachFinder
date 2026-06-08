/// Request payload for `POST /api/centers` — a coaching owner creating their
/// (single) center. The backend schema is `.strict()`, so [toJson] emits ONLY
/// the keys the create form collects: the required identity / contact / address
/// fields plus an optional description, and a server-mandated `location`.
library;

/// The create-center request. Required fields are non-nullable; [description]
/// is the one optional the minimal form collects. Boards, subjects, fees,
/// timings, and photos are enriched afterward via the Edit screen, so they are
/// intentionally absent here.
///
/// The backend requires a GeoJSON `location.coordinates [lng, lat]`, but the app
/// has no map / geocoding picker (fixed stack). We send a sensible default —
/// [defaultCoordinates] (the geographic centroid of India) — so a first-time
/// owner is never blocked; they can refine the precise location later through
/// the Edit form. See ADR 0043.
class CenterCreateRequest {
  /// Creates a center-create request from the form fields.
  const CenterCreateRequest({
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.phone,
    this.description,
  });

  /// Center display name.
  final String name;

  /// Street address.
  final String address;

  /// City.
  final String city;

  /// State / province.
  final String state;

  /// Postal / PIN code.
  final String pincode;

  /// Primary contact phone.
  final String phone;

  /// Optional free-text description, omitted from the payload when null/empty.
  final String? description;

  /// Default GeoJSON coordinates `[longitude, latitude]` — the centroid of
  /// India. Sent on every create because the backend requires a location and
  /// there is no in-app map picker yet; the owner refines it later via Edit.
  static const List<double> defaultCoordinates = <double>[78.9629, 20.5937];

  /// Serialises the strict create body. Only includes [description] when it is
  /// non-null and non-empty; always stamps the default [location].
  Map<String, dynamic> toJson() {
    final String? trimmedDescription = description?.trim();
    return <String, dynamic>{
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'phone': phone,
      if (trimmedDescription != null && trimmedDescription.isNotEmpty)
        'description': trimmedDescription,
      'location': const <String, dynamic>{
        'type': 'Point',
        'coordinates': defaultCoordinates,
      },
    };
  }
}
