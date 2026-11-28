import 'package:grocer_mate/core/storage/local_storage.dart';

import '../domain/entities/shopping.dart';
import '../domain/repositories/shopping_repository.dart';

class const LocalShoppingRepository(final LocalStorage store)
    implements ShoppingRepository {
  static const _key = 'shopping_v1';

  @override
  Future<ShoppingData> read() async {
    final json = await store.read(_key);
    return json == null ? const .new() : ShoppingData.fromJson(json);
  }

  @override
  Future<void> write(ShoppingData data) => store.write(_key, data.toJson());
}
