// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartProduct _$CartProductFromJson(Map<String, dynamic> json) => CartProduct(
  id: json['id'] as String,
  title: json['title'] as String,
  image: _readCartImage(json, 'image') as String,
  price: (json['price'] as num).toInt(),
  originalPrice: (json['originalPrice'] as num).toInt(),
  stock: (json['stock'] as num).toInt(),
);

Map<String, dynamic> _$CartProductToJson(CartProduct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'image': instance.image,
      'price': instance.price,
      'originalPrice': instance.originalPrice,
      'stock': instance.stock,
    };
