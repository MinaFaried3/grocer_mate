// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShoppingData _$ShoppingDataFromJson(Map<String, dynamic> json) => ShoppingData(
  cart:
      (json['cart'] as List<dynamic>?)
          ?.map((e) => CartLine.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  saved:
      (json['saved'] as List<dynamic>?)
          ?.map((e) => CartLine.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  pending: json['pending'] == null
      ? null
      : PendingPurchase.fromJson(json['pending'] as Map<String, dynamic>),
  lastOrder: json['lastOrder'] == null
      ? null
      : OrderReceipt.fromJson(json['lastOrder'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ShoppingDataToJson(ShoppingData instance) =>
    <String, dynamic>{
      'cart': instance.cart.map((e) => e.toJson()).toList(),
      'saved': instance.saved.map((e) => e.toJson()).toList(),
      'pending': instance.pending?.toJson(),
      'lastOrder': instance.lastOrder?.toJson(),
    };
