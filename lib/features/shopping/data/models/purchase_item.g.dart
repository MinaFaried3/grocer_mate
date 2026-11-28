// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PurchaseItem _$PurchaseItemFromJson(Map<String, dynamic> json) => PurchaseItem(
  productId: json['productId'] as String,
  qty: json['qty'] as num,
  expectedPrice: json['expectedPrice'] as num?,
);

Map<String, dynamic> _$PurchaseItemToJson(PurchaseItem instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'qty': instance.qty,
      'expectedPrice': ?instance.expectedPrice,
    };
