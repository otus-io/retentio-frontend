import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/auth/domain/account_limits.dart';
import 'package:retentio/l10n/app_localizations.dart';

void main() {
  late AppLocalizations en;

  setUp(() {
    en = lookupAppLocalizations(const Locale('en'));
  });

  test('accepts a username and secret inside the limits', () {
    expect(
      AccountLimits.limitMessage(en, username: 'ab', secret: 'password'),
      isNull,
    );
    expect(
      AccountLimits.limitMessage(en, username: '  小明  ', secret: 'a' * 64),
      isNull,
    );
    expect(
      AccountLimits.limitMessage(en, username: '明' * 32, secret: '😀' * 18),
      isNull,
    );
  });

  test('rejects a username outside 2 to 32 characters after trim', () {
    expect(
      AccountLimits.limitMessage(en, username: 'a', secret: 'password'),
      en.usernameLengthInvalid,
    );
    expect(
      AccountLimits.limitMessage(en, username: ' a ', secret: 'password'),
      en.usernameLengthInvalid,
    );
    expect(
      AccountLimits.limitMessage(en, username: '明', secret: 'password'),
      en.usernameLengthInvalid,
    );
    expect(
      AccountLimits.limitMessage(en, username: 'a' * 33, secret: 'password'),
      en.usernameLengthInvalid,
    );
    expect(
      AccountLimits.limitMessage(en, username: '明' * 33, secret: 'password'),
      en.usernameLengthInvalid,
    );
  });

  test('rejects a secret shorter than 8 characters', () {
    expect(
      AccountLimits.limitMessage(en, username: 'ab', secret: 'short'),
      en.passwordTooShort,
    );
    expect(
      AccountLimits.limitMessage(en, secret: 'a' * 7),
      en.passwordTooShort,
    );
  });

  test('rejects a secret longer than 64 characters', () {
    expect(
      AccountLimits.limitMessage(en, username: 'ab', secret: 'a' * 65),
      en.passwordTooLong,
    );
  });

  test('rejects a secret that exceeds 72 bytes', () {
    expect(
      AccountLimits.limitMessage(en, secret: '😀' * 19),
      en.passwordTooLong,
    );
  });

  test('skips the username check when no username is provided', () {
    expect(AccountLimits.limitMessage(en, secret: 'password'), isNull);
  });
}
