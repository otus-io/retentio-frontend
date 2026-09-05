import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/screen/qa/qa_column_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('returns null when nothing is stored', () async {
    expect(await QaColumnPrefs.load('deck-1'), isNull);
  });

  test('round-trips sorted indexes', () async {
    await QaColumnPrefs.save('deck-1', {2, 0, 1});
    expect(await QaColumnPrefs.load('deck-1'), {0, 1, 2});
  });

  test('ignores invalid stored payloads', () async {
    SharedPreferences.setMockInitialValues({'qa_columns_deck-1': 'not-json'});
    expect(await QaColumnPrefs.load('deck-1'), isNull);

    SharedPreferences.setMockInitialValues({
      'qa_columns_deck-1': '["x", -1, 2]',
    });
    expect(await QaColumnPrefs.load('deck-1'), {2});
  });
}
