// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inventory_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InventoryResponse _$InventoryResponseFromJson(Map<String, dynamic> json) =>
    InventoryResponse(
      productId: json['productId'] as String,
      stock: (json['stock'] as num).toInt(),
      backorderable: json['backorderable'] as bool?,
      etaDays: (json['etaDays'] as num?)?.toInt(),
    );

Map<String, dynamic> _$InventoryResponseToJson(InventoryResponse instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'stock': instance.stock,
      'backorderable': ?instance.backorderable,
      'etaDays': ?instance.etaDays,
    };
