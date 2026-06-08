/// Tests for [SubjectOption.fromJson] + value equality (used by the centre
/// subject multi-select).
library;

import 'package:coachfinder/features/owner/manage_center/data/models/subject_option.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubjectOption', () {
    test('parses _id and name', () {
      final s = SubjectOption.fromJson(<String, dynamic>{
        '_id': 's1',
        'name': 'Physics',
        'slug': 'physics',
      });
      expect(s.id, 's1');
      expect(s.name, 'Physics');
    });

    test('tolerates id fallback and missing name', () {
      final s = SubjectOption.fromJson(<String, dynamic>{'id': 's2'});
      expect(s.id, 's2');
      expect(s.name, '');
    });

    test('value equality by id + name', () {
      expect(
        const SubjectOption(id: 's1', name: 'Physics'),
        const SubjectOption(id: 's1', name: 'Physics'),
      );
      expect(
        const SubjectOption(id: 's1', name: 'Physics'),
        isNot(const SubjectOption(id: 's2', name: 'Physics')),
      );
    });
  });
}
