import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:path_provider/path_provider.dart';

import 'local_storage.dart';

class HiveLocalStorage implements LocalStorage {
  HiveLocalStorage({this._directory});

  final String? _directory;
  Future<Box<String>>? _opening;

  Future<Box<String>> get _box => _opening ??= _open();

  Future<Box<String>> _open() async {
    try {
      final path = kIsWeb
          ? null
          : _directory ?? (await getApplicationSupportDirectory()).path;
      return await Hive.openBox<String>('grocer_mate', path: path);
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> read(String key) async {
    final payload = (await _box).get(key);
    return payload == null ? null : jsonDecode(payload) as Map<String, dynamic>;
  }

  @override
  Future<void> write(String key, Map<String, Object?> value) async {
    final payload = jsonEncode(value);
    await (await _box).put(key, payload);
  }

  Future<void> close() async {
    final box = await _opening;
    await box?.close();
    _opening = null;
  }
}
