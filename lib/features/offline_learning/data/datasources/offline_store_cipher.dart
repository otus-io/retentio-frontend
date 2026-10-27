import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce/hive.dart';

const offlineStoreKeyName = 'offline_store_key';

/// AES cipher for the offline Hive boxes. The key is generated once per device
/// and kept in the platform secure storage, never in SharedPreferences.
///
/// Known limitation: the key is shared by every account on the device. The
/// `accountId:` key prefix separates accounts in the API, not in the Hive
/// files; per-account keys (e.g. derived with HKDF) would be needed for that.
Future<HiveAesCipher> offlineStoreCipher([
  FlutterSecureStorage storage = const FlutterSecureStorage(),
]) async {
  var encoded = await storage.read(key: offlineStoreKeyName);
  if (encoded == null) {
    encoded = base64Url.encode(Hive.generateSecureKey());
    await storage.write(key: offlineStoreKeyName, value: encoded);
  }
  return HiveAesCipher(base64Url.decode(encoded));
}
