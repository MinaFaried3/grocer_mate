// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockItem _$StockItemFromJson(Map<String, dynamic> json) => StockItem(
  productId: json['productId'] as String,
  stock: (json['stock'] as num).toInt(),
);

Map<String, dynamic> _$StockItemToJson(StockItem instance) => <String, dynamic>{
  'productId': instance.productId,
  'stock': instance.stock,
};
