import 'package:grocer_mate/core/storage/json_store.dart';

import '../domain/shopping.dart';

class LocalShoppingRepository implements ShoppingRepository {
  const LocalShoppingRepository(this.store);
  static const _key = 'shopping_v1';
  final JsonStore store;

  @override
  Future<ShoppingData> read() async {
    final json = await store.read(_key);
    return json == null ? const ShoppingData() : ShoppingData.fromJson(json);
  }

  @override
  Future<void> write(ShoppingData data) => store.write(_key, data.toJson());
}
