import 'dart:convert';

import 'package:retentio/l10n/app_localizations.dart';

/// Username is 2–32 Unicode characters after trim, with no whitespace left
/// inside. A new password is 8–64 Unicode characters, with no whitespace, and
/// at most 72 UTF-8 bytes so bcrypt can hash it. Login can skip that
/// whitespace check so an older password can still be submitted.
class AccountLimits {
  const AccountLimits._();

  static const usernameMin = 2;
  static const usernameMax = 32;
  static const passwordMin = 8;
  static const passwordMax = 64;
  static const passwordMaxBytes = 72;

  static final _whitespace = RegExp(r'\s', unicode: true);

  /// Returns a localized limit error, or null when [secret] and [username] are allowed.
  ///
  /// Pass [username] when the form collects one. Omit it when only a new password is set.
  /// Leading and trailing username whitespace is ignored. Whitespace left inside
  /// the username is refused. Whitespace in [secret] is refused unless
  /// [rejectSecretWhitespace] is false, which login uses so a password saved
  /// before that rule can still be submitted.
  static String? limitMessage(
    AppLocalizations loc, {
    String? username,
    required String secret,
    bool rejectSecretWhitespace = true,
  }) {
    if (username != null) {
      final trimmed = username.trim();
      if (_whitespace.hasMatch(trimmed)) {
        return loc.usernameContainsSpaces;
      }
      final chars = trimmed.runes.length;
      if (chars < usernameMin || chars > usernameMax) {
        return loc.usernameLengthInvalid;
      }
    }
    if (rejectSecretWhitespace && _whitespace.hasMatch(secret)) {
      return loc.passwordContainsSpaces;
    }
    final chars = secret.runes.length;
    if (chars < passwordMin) return loc.passwordTooShort;
    if (chars > passwordMax) return loc.passwordTooLong;
    if (utf8.encode(secret).length > passwordMaxBytes) {
      return loc.passwordTooManyBytes;
    }
    return null;
  }
}
