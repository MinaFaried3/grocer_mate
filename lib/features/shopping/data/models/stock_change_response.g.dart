// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_change_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockChangeResponse _$StockChangeResponseFromJson(Map<String, dynamic> json) =>
    StockChangeResponse(
      productId: json['productId'] as String,
      available: json['available'] as num,
    );

Map<String, dynamic> _$StockChangeResponseToJson(
  StockChangeResponse instance,
) => <String, dynamic>{
  'productId': instance.productId,
  'available': instance.available,
};
