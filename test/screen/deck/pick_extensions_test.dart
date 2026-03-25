import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/screen/deck/fact_add_composer/pick_extensions.dart';

void main() {
  test('includes common image video audio extensions', () {
    const all = AddFactPickExtensions.all;
    expect(all, contains('mp3'));
    expect(all, contains('mp4'));
    expect(all, contains('jpg'));
    expect(all, contains('heic'));
  });
}
