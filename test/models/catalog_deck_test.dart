import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/catalog_deck.dart';

void main() {
  Map<String, dynamic> row({Object? qaVerified}) => {
    'id': 'src-1',
    'name': 'N5',
    'owner': 'alice',
    'fields': ['A', 'B'],
    'published_version': 2,
    'fact_count': 10,
    'qa_verified': ?qaVerified,
  };

  test('reads qa_verified and defaults it to false', () {
    expect(CatalogDeck.fromJson(row(qaVerified: true)).qaVerified, isTrue);
    expect(CatalogDeck.fromJson(row()).qaVerified, isFalse);
    expect(
      CatalogDeck.fromJson(row(qaVerified: true)).toJson()['qa_verified'],
      isTrue,
    );
  });
}
