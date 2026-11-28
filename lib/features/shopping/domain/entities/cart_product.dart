import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:grocer_mate/features/catalog/domain/entities/catalog.dart';
import 'package:json_annotation/json_annotation.dart';

part 'cart_product.g.dart';

Object? _readCartImage(Map<dynamic, dynamic> json, String key) =>
    switch (json) {
      {'image': String image} when image.trim().isNotEmpty => image,
      {'images': [String first, ...]} when first.trim().isNotEmpty => first,
      _ => throw const FormatException('Cart product is missing its image.'),
    };

@JsonSerializable()
class const CartProduct({
  required final String id,
  required final String title,
  @JsonKey(readValue: _readCartImage) required final String image,
  required final int price,
  required final int originalPrice,
  required final int stock,
}) {
  this : assert(price >= 0), assert(originalPrice >= 0), assert(stock >= 0);

  factory fromJson(Json json) {
    readText(json, 'id');
    readText(json, 'title');
    readInt(json, 'price');
    readInt(json, 'originalPrice');
    readInt(json, 'stock');
    return _$CartProductFromJson(json);
  }

  Json toJson() => _$CartProductToJson(this);

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
