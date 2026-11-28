import 'package:grocer_mate/core/storage/local_storage.dart';

import '../models/shopping_data.dart';

class const LocalShoppingSource(final LocalStorage _store) {
  static const _key = 'shopping_v1';

  Future<ShoppingData?> read() async {
    final json = await _store.read(_key);
    return json == null ? null : ShoppingData.fromJson(json);
  }

  Future<void> write(ShoppingData data) => _store.write(_key, data.toJson());
}
