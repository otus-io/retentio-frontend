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

  test('reads contributors and defaults them to none', () {
    final credited = CatalogDeck.fromJson({
      ...row(),
      'contributors': ['bob', 'carol'],
      'contributor_count': 12,
    });
    expect(credited.contributors, ['bob', 'carol']);
    expect(credited.contributorCount, 12);
    expect(credited.toJson()['contributor_count'], 12);

    final none = CatalogDeck.fromJson(row());
    expect(none.contributors, isEmpty);
    expect(none.contributorCount, 0);
  });

  test('reads qa_verified and defaults it to false', () {
    expect(CatalogDeck.fromJson(row(qaVerified: true)).qaVerified, isTrue);
    expect(CatalogDeck.fromJson(row()).qaVerified, isFalse);
    for (final loose in <Object>['true', 1, 'yes']) {
      expect(CatalogDeck.fromJson(row(qaVerified: loose)).qaVerified, isFalse);
    }
    expect(
      CatalogDeck.fromJson(row(qaVerified: true)).toJson()['qa_verified'],
      isTrue,
    );
  });
}
