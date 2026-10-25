import 'dart:convert';

import 'package:retentio/l10n/app_localizations.dart';

/// Shared username and password length rules.
///
/// Username is 2–32 Unicode characters after trim. Password is 8–64 Unicode
/// characters, and at most 72 UTF-8 bytes so bcrypt can hash it.
class AccountLimits {
  const AccountLimits._();

  static const usernameMin = 2;
  static const usernameMax = 32;
  static const passwordMin = 8;
  static const passwordMax = 64;
  static const passwordMaxBytes = 72;

  static final _whitespace = RegExp(r'\s', unicode: true);

  /// Returns a localized length error, or null when [secret] and [username] are in range.
  ///
  /// Pass [username] when the form collects one. Omit it when only a new password is set.
  /// Set [rejectSpaces] on registration so a username like `a b` is refused. Login leaves
  /// it false so an existing username that contains a space can still sign in.
  static String? limitMessage(
    AppLocalizations loc, {
    String? username,
    required String secret,
    bool rejectSpaces = false,
  }) {
    if (username != null) {
      final trimmed = username.trim();
      if (rejectSpaces && _whitespace.hasMatch(trimmed)) {
        return loc.usernameContainsSpaces;
      }
      final chars = trimmed.runes.length;
      if (chars < usernameMin || chars > usernameMax) {
        return loc.usernameLengthInvalid;
      }
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
