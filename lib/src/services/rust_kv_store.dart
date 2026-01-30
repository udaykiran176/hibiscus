import 'dart:convert';

import 'package:hibiscus/src/rust/api/settings.dart' as rust_settings;

class RustKvStore {
  static Future<String?> getString(String key) => rust_settings.getKv(key: key);

  static Future<void> setString(String key, String value) async {
    await rust_settings.setKv(key: key, value: value);
  }

  static Future<void> remove(String key) async {
    await rust_settings.deleteKv(key: key);
  }

  static Future<bool?> getBool(String key) async {
    final raw = await getString(key);
    if (raw == null) return null;
    final s = raw.trim().toLowerCase();
    if (s.isEmpty) return null;
    if (s == '1' || s == 'true') return true;
    if (s == '0' || s == 'false') return false;
    return null;
  }

  static Future<void> setBool(String key, bool value) =>
      setString(key, value ? 'true' : 'false');

  static Future<List<String>?> getStringList(String key) async {
    final raw = await getString(key);
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;
    try {
      final decoded = jsonDecode(s);
      if (decoded is! List) return null;
      return decoded.map((e) => e?.toString()).whereType<String>().toList();
    } catch (_) {
      return null;
    }
  }

  static Future<void> setStringList(String key, List<String> value) =>
      setString(key, jsonEncode(value));
}

