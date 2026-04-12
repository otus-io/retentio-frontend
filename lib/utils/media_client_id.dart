import 'dart:math';

/// Alphabet and length match [retentio-backend/api/helpers/nanoid_id.go] and
/// server-side `helpers.GenerateID(10)` for `POST /api/media` when `client_id` is omitted.
const _mediaIdAlphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
const mediaClientIdLength = 10;

final _rand = Random.secure();

/// New id for multipart `client_id` (idempotent upload key).
String newMediaClientId() {
  final b = StringBuffer();
  for (var i = 0; i < mediaClientIdLength; i++) {
    b.write(_mediaIdAlphabet[_rand.nextInt(_mediaIdAlphabet.length)]);
  }
  return b.toString();
}
