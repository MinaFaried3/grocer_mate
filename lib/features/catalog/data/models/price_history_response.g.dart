// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'price_history_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PriceHistoryResponse _$PriceHistoryResponseFromJson(
  Map<String, dynamic> json,
) => PriceHistoryResponse(
  productId: json['productId'] as String,
  history: (json['history'] as List<dynamic>).map((e) => e as num).toList(),
);

Map<String, dynamic> _$PriceHistoryResponseToJson(
  PriceHistoryResponse instance,
) => <String, dynamic>{
  'productId': instance.productId,
  'history': instance.history,
};
