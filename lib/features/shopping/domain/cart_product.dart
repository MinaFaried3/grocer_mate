import 'package:grocer_mate/features/catalog/domain/catalog.dart';

class CartProduct {
  const CartProduct({
    required this.id,
    required this.title,
    required this.image,
    required this.price,
    required this.originalPrice,
    required this.stock,
  }) : assert(price >= 0),
       assert(originalPrice >= 0),
       assert(stock >= 0);

  final String id;
  final String title;
  final String image;
  final int price;
  final int originalPrice;
  final int stock;

  factory CartProduct.fromProduct(Product product) => CartProduct(
    id: product.id,
    title: product.title,
    image: product.images.first,
    price: product.price,
    originalPrice: product.originalPrice,
    stock: product.stock,
  );

  CartProduct withAvailability({required int price, required int stock}) =>
      CartProduct(
        id: id,
        title: title,
        image: image,
        price: price,
        originalPrice: originalPrice,
        stock: stock,
      );
}
