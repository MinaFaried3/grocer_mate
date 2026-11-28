// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping.dart';

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

OrderReceipt _$OrderReceiptFromJson(Map<String, dynamic> json) => OrderReceipt(
  id: json['id'] as String,
  total: (json['total'] as num).toInt(),
);

Map<String, dynamic> _$OrderReceiptToJson(OrderReceipt instance) =>
    <String, dynamic>{'id': instance.id, 'total': instance.total};

PendingPurchase _$PendingPurchaseFromJson(Map<String, dynamic> json) =>
    PendingPurchase(
      json['id'] as String,
      (json['lines'] as List<dynamic>)
          .map((e) => CartLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      attempted: json['attempted'] as bool? ?? false,
    );

Map<String, dynamic> _$PendingPurchaseToJson(PendingPurchase instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lines': instance.lines.map((e) => e.toJson()).toList(),
      'attempted': instance.attempted,
    };

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
