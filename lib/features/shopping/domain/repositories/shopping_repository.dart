import '../entities/shopping.dart';

abstract interface class ShoppingRepository {
  Future<ShoppingData> read();
  Future<void> write(ShoppingData data);
}
