// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cart_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CartLine _$CartLineFromJson(Map<String, dynamic> json) => CartLine(
  CartProduct.fromJson(json['product'] as Map<String, dynamic>),
  (json['quantity'] as num).toInt(),
);

Map<String, dynamic> _$CartLineToJson(CartLine instance) => <String, dynamic>{
  'product': instance.product.toJson(),
  'quantity': instance.quantity,
};
