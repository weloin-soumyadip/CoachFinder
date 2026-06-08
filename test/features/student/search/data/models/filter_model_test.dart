import 'package:coachfinder/features/student/search/data/models/filter_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SearchBoard.wireValue', () {
    test('maps every enum value to its exact backend string', () {
      expect(SearchBoard.cbse.wireValue, 'CBSE');
      expect(SearchBoard.icse.wireValue, 'ICSE');
      expect(SearchBoard.state.wireValue, 'State');
      expect(SearchBoard.ib.wireValue, 'IB');
      expect(SearchBoard.igcse.wireValue, 'IGCSE');
      expect(SearchBoard.other.wireValue, 'Other');
    });
  });

  group('SearchFilters', () {
    test('isEmpty is true for the default const instance', () {
      expect(const SearchFilters().isEmpty, true);
    });

    test('isEmpty is false once any field is set', () {
      expect(const SearchFilters(q: 'maths').isEmpty, false);
      expect(const SearchFilters(city: 'Pune').isEmpty, false);
      expect(const SearchFilters(board: SearchBoard.cbse).isEmpty, false);
      expect(const SearchFilters(minRating: 4).isEmpty, false);
    });

    test('copyWith replaces only the named fields', () {
      const base = SearchFilters(q: 'maths', city: 'Pune');
      final next = base.copyWith(city: 'Mumbai');
      expect(next.q, 'maths');
      expect(next.city, 'Mumbai');
    });

    test('hasActiveFilters ignores q and tracks the other refinements', () {
      expect(const SearchFilters().hasActiveFilters, false);
      // A query alone is not an "active filter".
      expect(const SearchFilters(q: 'maths').hasActiveFilters, false);
      expect(const SearchFilters(city: 'Pune').hasActiveFilters, true);
      expect(
          const SearchFilters(board: SearchBoard.icse).hasActiveFilters, true);
      expect(const SearchFilters(minFees: 500).hasActiveFilters, true);
    });
  });

  group('SearchFilters.toQueryParameters (teacher / coaching)', () {
    test('includes all set fields with the board wire string', () {
      const filters = SearchFilters(
        q: 'physics',
        subject: 'phy',
        city: 'Bengaluru',
        board: SearchBoard.icse,
        minRating: 4.5,
        minFees: 500,
        maxFees: 3000,
      );
      final params = filters.toQueryParameters(forWebinar: false);
      expect(params['q'], 'physics');
      expect(params['subject'], 'phy');
      expect(params['city'], 'Bengaluru');
      expect(params['board'], 'ICSE');
      expect(params['minRating'], 4.5);
      expect(params['minFees'], 500);
      expect(params['maxFees'], 3000);
    });

    test('omits null and empty fields entirely', () {
      const filters = SearchFilters(q: '');
      final params = filters.toQueryParameters(forWebinar: false);
      expect(params.containsKey('q'), false);
      expect(params.containsKey('subject'), false);
      expect(params.containsKey('city'), false);
      expect(params.containsKey('board'), false);
      expect(params.containsKey('minRating'), false);
      expect(params, isEmpty);
    });
  });

  group('SearchFilters.toQueryParameters (webinar)', () {
    test('includes only q and excludes teacher/coaching-only fields', () {
      const filters = SearchFilters(
        q: 'calculus',
        subject: 'maths',
        city: 'Pune',
        board: SearchBoard.cbse,
        minRating: 4,
        minFees: 100,
        maxFees: 900,
      );
      final params = filters.toQueryParameters(forWebinar: true);
      expect(params['q'], 'calculus');
      expect(params.containsKey('subject'), false);
      expect(params.containsKey('city'), false);
      expect(params.containsKey('board'), false);
      expect(params.containsKey('minRating'), false);
      expect(params.containsKey('minFees'), false);
      expect(params.containsKey('maxFees'), false);
    });

    test('omits q when blank', () {
      const filters = SearchFilters(city: 'Pune');
      final params = filters.toQueryParameters(forWebinar: true);
      expect(params, isEmpty);
    });
  });
}
