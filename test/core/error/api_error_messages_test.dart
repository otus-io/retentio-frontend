import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/core/error/api_error_messages.dart';
import 'package:retentio/l10n/app_localizations.dart';

void main() {
  late AppLocalizations en;
  late AppLocalizations zh;

  setUp(() {
    en = lookupAppLocalizations(const Locale('en'));
    zh = lookupAppLocalizations(const Locale('zh'));
  });

  group('ApiErrorMessages.resolve', () {
    test('empty msg returns errorUnknown', () {
      expect(ApiErrorMessages.resolve(null, en), en.errorUnknown);
      expect(ApiErrorMessages.resolve('  ', zh), zh.errorUnknown);
    });

    test('maps known auth errors', () {
      expect(
        ApiErrorMessages.resolve('Invalid credentials', en),
        en.authInvalidCredentials,
      );
      expect(
        ApiErrorMessages.resolve('Username already exists', zh),
        zh.authUsernameAlreadyExists,
      );
    });

    test('maps deck sharing errors', () {
      expect(
        ApiErrorMessages.resolve('cannot import your own deck', en),
        en.discoveryImportSelf,
      );
      expect(
        ApiErrorMessages.resolve('no changes to publish', zh),
        zh.errorNoChangesToPublish,
      );
    });

    test('maps parameterized fact validation errors', () {
      expect(
        ApiErrorMessages.resolve('fact 2: at least one entry is required', en),
        en.apiFactEntryRequired(2),
      );
      expect(
        ApiErrorMessages.resolve(
          'fact 0: at least one entry must have text, audio, image, video, or json',
          zh,
        ),
        zh.apiFactEntryContent(0),
      );
    });

    test('maps media mime pattern', () {
      expect(
        ApiErrorMessages.resolve('unsupported media type: image/bmp', en),
        en.apiUnsupportedMediaMime('image/bmp'),
      );
    });

    test('maps unlisted server errors to errorServerError', () {
      expect(
        ApiErrorMessages.resolve('Error retrieving/updating/deleting tag', en),
        en.errorServerError,
      );
      expect(
        ApiErrorMessages.resolve('Failed to do something new', zh),
        zh.errorServerError,
      );
    });

    test('falls back to raw message for unknown non-server errors', () {
      const raw = 'some new backend message';
      expect(ApiErrorMessages.resolve(raw, en), raw);
    });

    test('maps deck study sentinel errors', () {
      expect(
        ApiErrorMessages.resolve('submit_card_failed', en),
        en.errorSubmitCardFailed,
      );
      expect(
        ApiErrorMessages.resolve('delete_card_failed', zh),
        zh.deleteCardFailed,
      );
    });

    test('maps tag client fallbacks', () {
      expect(
        ApiErrorMessages.resolve('Could not create tag', en),
        en.tagCreateFailed,
      );
    });
  });
}
