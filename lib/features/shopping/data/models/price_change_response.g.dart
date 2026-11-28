// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_change_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PriceChangeResponse _$PriceChangeResponseFromJson(Map<String, dynamic> json) =>
    PriceChangeResponse(
      productId: json['productId'] as String,
      newPrice: json['newPrice'] as num,
      oldPrice: json['oldPrice'] as num?,
    );

Map<String, dynamic> _$PriceChangeResponseToJson(
  PriceChangeResponse instance,
) => <String, dynamic>{
  'productId': instance.productId,
  'newPrice': instance.newPrice,
  'oldPrice': ?instance.oldPrice,
};
