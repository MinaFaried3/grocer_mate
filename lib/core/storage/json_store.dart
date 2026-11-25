import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class JsonStore {
  const JsonStore(this.preferences);

  final SharedPreferencesAsync preferences;

  Future<Map<String, dynamic>?> read(String key) async {
    final raw = await preferences.getString(key);
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> write(String key, Map<String, Object?> value) =>
      preferences.setString(key, jsonEncode(value));
}
