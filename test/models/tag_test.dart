import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/tag.dart';

void main() {
  group('Tag', () {
    test('fromJson parses all fields correctly', () {
      final tag = Tag.fromJson({
        'id': 'tag-1',
        'name': 'Flutter',
        'description': 'Flutter related cards',
      });
      expect(tag.id, 'tag-1');
      expect(tag.name, 'Flutter');
      expect(tag.description, 'Flutter related cards');
    });

    test('fromJson falls back to empty string for missing id', () {
      final tag = Tag.fromJson({'name': 'no-id', 'description': ''});
      expect(tag.id, '');
      expect(tag.name, 'no-id');
    });

    test('fromJson falls back to empty string for missing name', () {
      final tag = Tag.fromJson({'id': 'x', 'description': 'desc'});
      expect(tag.name, '');
    });

    test('fromJson falls back to empty string for missing description', () {
      final tag = Tag.fromJson({'id': 'x', 'name': 'y'});
      expect(tag.description, '');
    });

    test('fromJson accepts all-empty map without throwing', () {
      final tag = Tag.fromJson({});
      expect(tag.id, '');
      expect(tag.name, '');
      expect(tag.description, '');
    });

    test('toJson round-trips correctly', () {
      const tag = Tag(id: 'tag-2', name: 'Dart', description: 'Dart basics');
      final json = tag.toJson();
      expect(json['id'], 'tag-2');
      expect(json['name'], 'Dart');
      expect(json['description'], 'Dart basics');
    });

    test('fromJson → toJson round-trip preserves all fields', () {
      final original = {
        'id': 'rt-42',
        'name': 'Retentio',
        'description': 'Spaced repetition',
      };
      final tag = Tag.fromJson(original);
      final json = tag.toJson();
      expect(json['id'], original['id']);
      expect(json['name'], original['name']);
      expect(json['description'], original['description']);
    });

    test('toJson includes all three keys even when empty', () {
      const tag = Tag(id: '', name: '', description: '');
      final json = tag.toJson();
      expect(json.containsKey('id'), isTrue);
      expect(json.containsKey('name'), isTrue);
      expect(json.containsKey('description'), isTrue);
    });
  });
}
