import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/extensions/map_extension.dart';

void main() {
  group('MapExtension has / doesntHave', () {
    test('has returns true when key exists and value matches', () {
      final map = <String, dynamic>{'id': 1, 'name': 'Desk', 'price': 200};
      expect(map.has('id', 1), isTrue);
      expect(map.has('name', 'Desk'), isTrue);
    });

    test('has returns false when key exists but value does not match', () {
      final map = <String, dynamic>{'id': 1, 'name': 'Desk'};
      expect(map.has('id', 2), isFalse);
      expect(map.has('name', 'Table'), isFalse);
    });

    test('has returns false when key does not exist', () {
      final map = <String, dynamic>{'id': 1};
      expect(map.has('missing', 1), isFalse);
    });

    test('doesntHave returns opposite of has', () {
      final map = <String, dynamic>{'name': 'John', 'age': 30};
      expect(map.doesntHave('gender', 'male'), isTrue);
      expect(map.doesntHave('name', 'John'), isFalse);
    });

    // Type mismatch case the bot mentioned: when key type T is not String,
    // has() must accept T (e.g. int), not String. This compiles only if
    // the extension uses "T key" instead of "String key".
    test('has works with non-String key type (Map<int, int>)', () {
      final map = <int, int>{1: 10, 2: 20};
      expect(map.has(1, 10), isTrue);
      expect(map.has(1, 20), isFalse);
      expect(map.has(3, 10), isFalse);
    });

    test('doesntHave works with non-String key type (Map<int, int>)', () {
      final map = <int, int>{1: 10, 2: 20};
      expect(map.doesntHave(3, 10), isTrue);
      expect(map.doesntHave(1, 10), isFalse);
    });
  });

  group('MapExtension retainKeys', () {
    test('retainKeys keeps only specified keys', () {
      final map = <String, dynamic>{
        'id': 1,
        'name': 'John',
        'age': 30,
      };
      final result = map.retainKeys(['id', 'name']);
      expect(result, {'id': 1, 'name': 'John'});
      expect(map, same(result));
    });

    test('retainKeys with non-existent keys removes those entries', () {
      final map = <String, dynamic>{'a': 1, 'b': 2, 'c': 3};
      map.retainKeys(['a', 'c']);
      expect(map, {'a': 1, 'c': 3});
    });
  });

  group('MapExtension getId', () {
    test('getId returns id value when present', () {
      final map = <String, dynamic>{'id': 111, 'name': 'Desk'};
      expect(map.getId, 111);
    });

    test('getId returns null when id key missing', () {
      final map = <String, dynamic>{'name': 'Chair'};
      expect(map.getId, isNull);
    });

    test('getId returns null when id value is null', () {
      final map = <String, dynamic>{'id': null, 'name': 'Desk'};
      expect(map.getId, isNull);
    });
  });

  group('MapExtension diffKeys', () {
    test('diffKeys returns entries whose keys are not in other map', () {
      final map = <String, dynamic>{'a': 1, 'b': 2, 'c': 3};
      final other = <String, dynamic>{'b': 20};
      final result = map.diffKeys(other);
      expect(result, {'a': 1, 'c': 3});
    });

    test('diffKeys returns empty when all keys overlap', () {
      final map = <String, dynamic>{'a': 1, 'b': 2};
      final other = <String, dynamic>{'a': 10, 'b': 20};
      expect(map.diffKeys(other), isEmpty);
    });
  });

  group('MapExtension diffValues', () {
    test('diffValues returns entries whose values are not in other map', () {
      final map = <String, dynamic>{'a': 1, 'b': 2, 'c': 3};
      final other = <String, dynamic>{'x': 2};
      final result = map.diffValues(other);
      expect(result, {'a': 1, 'c': 3});
    });
  });

  group('MapExtension getBool', () {
    test('getBool returns true/false for bool values', () {
      final map = <String, dynamic>{'isAdmin': true, 'isActive': false};
      expect(map.getBool('isAdmin'), isTrue);
      expect(map.getBool('isActive'), isFalse);
    });

    test('getBool returns false for missing key', () {
      final map = <String, dynamic>{'isAdmin': true};
      expect(map.getBool('isDeleted'), isFalse);
    });

    test('getBool parses string "true" as true', () {
      final map = <String, dynamic>{'flag': 'true'};
      expect(map.getBool('flag'), isTrue);
    });
  });

  group('MapExtension getJsonMap', () {
    test('getJsonMap decodes JSON string to map', () {
      final map = <String, dynamic>{
        'payload': '{"foo": "bar", "n": 42}',
      };
      expect(map.getJsonMap('payload'), {'foo': 'bar', 'n': 42});
    });

    test('getJsonMap returns null for missing key', () {
      final map = <String, dynamic>{};
      expect(map.getJsonMap('payload'), isNull);
    });

    test('getJsonMap returns null for invalid JSON', () {
      final map = <String, dynamic>{'payload': 'not json'};
      expect(map.getJsonMap('payload'), isNull);
    });
  });

  group('MapExtension getJsonMapList', () {
    test('getJsonMapList decodes JSON array of objects', () {
      final map = <String, dynamic>{
        'items': '[{"a":1},{"b":2}]',
      };
      final result = map.getJsonMapList('items');
      expect(result, isNotNull);
      expect(result!.length, 2);
      expect(result[0], {'a': 1});
      expect(result[1], {'b': 2});
    });

    test('getJsonMapList returns null for missing key', () {
      final map = <String, dynamic>{};
      expect(map.getJsonMapList('items'), isNull);
    });

    test('getJsonMapList returns null for invalid JSON', () {
      final map = <String, dynamic>{'items': 'not json array'};
      expect(map.getJsonMapList('items'), isNull);
    });
  });

  group('MapExtension getInt', () {
    test('getInt returns int for numeric key', () {
      final map = <String, dynamic>{'id': 11, 'age': 30};
      expect(map.getInt('id'), 11);
      expect(map.getInt('age'), 30);
    });

    test('getInt parses string number', () {
      final map = <String, dynamic>{'count': '42'};
      expect(map.getInt('count'), 42);
    });

    test('getInt returns null for missing key', () {
      final map = <String, dynamic>{'id': 11};
      expect(map.getInt('address'), isNull);
    });

    test('getInt returns null for non-numeric value', () {
      final map = <String, dynamic>{'name': 'John'};
      expect(map.getInt('name'), isNull);
    });
  });

  group('MapExtension getDouble', () {
    test('getDouble returns double for numeric key', () {
      final map = <String, dynamic>{'price': 27.32};
      expect(map.getDouble('price'), 27.32);
    });

    test('getDouble parses string number', () {
      final map = <String, dynamic>{'qty': '27.32'};
      expect(map.getDouble('qty'), 27.32);
    });

    test('getDouble returns null for missing key', () {
      final map = <String, dynamic>{};
      expect(map.getDouble('size'), isNull);
    });
  });

  group('MapExtension getString', () {
    test('getString returns string value when present', () {
      final map = <String, dynamic>{'username': 'thor', 'age': 35};
      expect(map.getString('username'), 'thor');
    });

    test('getString returns default when key missing', () {
      final map = <String, dynamic>{'username': 'thor'};
      expect(
        map.getString('email', 'not_provided@example.com'),
        'not_provided@example.com',
      );
    });

    test('getString returns default when value is not String', () {
      final map = <String, dynamic>{'age': 35};
      expect(map.getString('age', 'unknown'), 'unknown');
    });
  });

  group('MapExtension getList', () {
    test('getList returns list for key', () {
      final map = <String, dynamic>{
        'items': [1, 2, 3, 4],
        'prices': [20.0, 30.0, 40.0],
      };
      expect(map.getList<int>('items'), [1, 2, 3, 4]);
      expect(map.getList<double>('prices'), [20.0, 30.0, 40.0]);
    });

    test('getList returns empty list for missing key', () {
      final map = <String, dynamic>{'items': [1, 2, 3]};
      expect(map.getList<int>('invalidKey'), isEmpty);
    });

    test('getList returns empty list when value is not a list', () {
      final map = <String, dynamic>{'items': 'not a list'};
      expect(map.getList<int>('items'), isEmpty);
    });
  });

  group('MapExtension match', () {
    test('match returns value when key exists', () {
      final map = <String, String>{
        'apple': 'red',
        'banana': 'yellow',
        'orange': 'orange',
      };
      expect(map.match('apple'), 'red');
      expect(map.match('banana'), 'yellow');
    });

    test('match returns default when key missing', () {
      final map = <String, String>{'apple': 'red'};
      expect(map.match('pear'), 'Invalid input');
      expect(map.match('pear', 'N/A'), 'N/A');
    });
  });

  group('MapExtension pick', () {
    test('pick returns map with only specified keys', () {
      final map = <String, String>{
        'apple': 'red',
        'banana': 'yellow',
        'orange': 'orange',
      };
      expect(map.pick(['apple']), {'apple': 'red'});
      expect(map.pick(['orange', 'pear']), {'orange': 'orange'});
    });

    test('pick ignores keys not in map', () {
      final map = <String, dynamic>{'a': 1, 'b': 2};
      expect(map.pick(['a', 'c']), {'a': 1});
    });

    test('pick returns empty map when no keys match', () {
      final map = <String, dynamic>{'a': 1, 'b': 2};
      expect(map.pick(['x', 'y']), isEmpty);
    });
  });
}
