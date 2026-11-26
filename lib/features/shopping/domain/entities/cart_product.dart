import 'package:grocer_mate/features/catalog/domain/entities/catalog.dart';

class const CartProduct({
  required final String id,
  required final String title,
  required final String image,
  required final int price,
  required final int originalPrice,
  required final int stock,
}) {
  this : assert(price >= 0), assert(originalPrice >= 0), assert(stock >= 0);

  factory fromProduct(Product product) => .new(
    id: product.id,
    title: product.title,
    image: product.images.first,
    price: product.price,
    originalPrice: product.originalPrice,
    stock: product.stock,
  );

  CartProduct withAvailability({required int price, required int stock}) =>
      .new(
        id: id,
        title: title,
        image: image,
        price: price,
        originalPrice: originalPrice,
        stock: stock,
      );
}
