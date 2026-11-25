import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/shopping.dart';

class LocalStore {
  LocalStore(this.preferences);

  final SharedPreferencesAsync preferences;

  Future<Map<String, dynamic>?> read(String key) async {
    final raw = await preferences.getString(key);
    return raw == null ? null : jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> write(String key, Map<String, Object?> value) =>
      preferences.setString(key, jsonEncode(value));
}

class LocalShoppingRepository implements ShoppingRepository {
  const LocalShoppingRepository(this.store);
  static const _key = 'shopping_v1';
  final LocalStore store;

  @override
  Future<ShoppingData> read() async {
    final json = await store.read(_key);
    return json == null ? const ShoppingData() : ShoppingData.fromJson(json);
  }

  @override
  Future<void> write(ShoppingData data) => store.write(_key, data.toJson());
}
