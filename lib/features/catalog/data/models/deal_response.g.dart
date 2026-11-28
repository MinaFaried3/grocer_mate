// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deal_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DealResponse _$DealResponseFromJson(Map<String, dynamic> json) => DealResponse(
  productId: json['productId'] as String,
  dealPrice: json['dealPrice'] as num,
  endsAt: json['endsAt'] as String,
);

Map<String, dynamic> _$DealResponseToJson(DealResponse instance) =>
    <String, dynamic>{
      'productId': instance.productId,
      'dealPrice': instance.dealPrice,
      'endsAt': instance.endsAt,
    };
