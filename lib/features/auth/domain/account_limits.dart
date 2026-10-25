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

  /// Returns a localized length error, or null when [secret] and [username] are in range.
  ///
  /// Pass [username] when the form collects one. Omit it when only a new password is set.
  static String? limitMessage(
    AppLocalizations loc, {
    String? username,
    required String secret,
  }) {
    if (username != null) {
      final chars = username.trim().runes.length;
      if (chars < usernameMin || chars > usernameMax) {
        return loc.usernameLengthInvalid;
      }
    }
    final chars = secret.runes.length;
    if (chars < passwordMin) return loc.passwordTooShort;
    if (chars > passwordMax || utf8.encode(secret).length > passwordMaxBytes) {
      return loc.passwordTooLong;
    }
    return null;
  }
}
