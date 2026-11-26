import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'local_storage.dart';

class SecureLocalStorage implements LocalStorage {
  static const _storage = FlutterSecureStorage();

  Future<void> _pendingWrites = Future.value();

  @override
  Future<Map<String, dynamic>?> read(String key) async {
    await _pendingWrites;
    final raw = await _storage.read(key: key);
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  @override
  Future<void> write(String key, Map<String, Object?> value) async {
    final encoded = jsonEncode(value);
    // The browser plugin initializes one encryption key for all entries.
    final write = _pendingWrites.then(
      (_) => _storage.write(key: key, value: encoded),
    );
    _pendingWrites = write.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    await write;
  }
}
