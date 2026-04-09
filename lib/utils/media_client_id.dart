import 'package:nanoid/nanoid.dart';

/// Alphabet and length match [retentio-backend/api/helpers/nanoid_id.go] and
/// server-side `helpers.GenerateID(10)` for `POST /api/media` when `client_id` is omitted.
const _mediaIdAlphabet = 'abcdefghijklmnopqrstuvwxyz0123456789';
const mediaClientIdLength = 10;

/// New id for multipart `client_id` (idempotent upload key).
String newMediaClientId() =>
    customAlphabet(_mediaIdAlphabet, mediaClientIdLength);
