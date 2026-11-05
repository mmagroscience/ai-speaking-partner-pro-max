import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps API keys out of plain-text preferences on mobile.
///
/// Android uses the platform keystore (RSA-OAEP + AES-GCM), iOS/macOS use the
/// Keychain. When secure storage is unavailable — desktop test runs, browsers,
/// or a locked keystore — callers fall back to `SharedPreferences`.
class SecureStore {
  SecureStore._();

  static const _storage = FlutterSecureStorage(aOptions: AndroidOptions());
  static const _apiKeysKey = 'apiKeys.v1';

  /// Widget tests have no platform plugin, so they opt out explicitly.
  @visibleForTesting
  static bool disabled = false;

  /// Web storage is only available on HTTPS/localhost, and the plugin is not
  /// present in unit tests. Both cases are handled by the caller's fallback.
  static bool get supported => !kIsWeb && !disabled;

  static Future<List<String>> readApiKeys() async {
    if (!supported) return const [];
    try {
      final raw = await _storage.read(key: _apiKeysKey);
      if (raw == null || raw.trim().isEmpty) return const [];
      return raw
          .split('\n')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Returns `true` when the keys were stored securely.
  static Future<bool> writeApiKeys(List<String> keys) async {
    if (!supported) return false;
    try {
      if (keys.isEmpty) {
        await _storage.delete(key: _apiKeysKey);
      } else {
        await _storage.write(key: _apiKeysKey, value: keys.join('\n'));
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> clear() async {
    if (!supported) return;
    try {
      await _storage.delete(key: _apiKeysKey);
    } catch (_) {
      // Nothing else to do — a fresh install clears the keystore anyway.
    }
  }
}
