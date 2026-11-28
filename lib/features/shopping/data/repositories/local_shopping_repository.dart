import '../../domain/repositories/shopping_repository.dart';
import '../models/shopping_data.dart';
import '../sources/local_shopping_source.dart';

class const LocalShoppingRepository(final LocalShoppingSource _source)
    implements ShoppingRepository {
  @override
  Future<ShoppingData> read() async => await _source.read() ?? const .new();

  @override
  Future<void> write(ShoppingData data) => _source.write(data);
}
