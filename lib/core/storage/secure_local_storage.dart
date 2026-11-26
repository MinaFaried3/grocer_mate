import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'local_storage.dart';

class const SecureLocalStorage() implements LocalStorage {
  static const _storage = FlutterSecureStorage();

  @override
  Future<Map<String, dynamic>?> read(String key) async {
    final raw = await _storage.read(key: key);
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  @override
  Future<void> write(String key, Map<String, Object?> value) =>
      _storage.write(key: key, value: jsonEncode(value));
}
