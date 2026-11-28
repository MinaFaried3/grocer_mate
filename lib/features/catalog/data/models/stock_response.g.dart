// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StockResponse _$StockResponseFromJson(Map<String, dynamic> json) =>
    StockResponse(
      stocks: (json['stocks'] as List<dynamic>)
          .map((e) => StockItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      timestamp: json['timestamp'] as String?,
    );

Map<String, dynamic> _$StockResponseToJson(StockResponse instance) =>
    <String, dynamic>{
      'stocks': instance.stocks.map((e) => e.toJson()).toList(),
      'timestamp': ?instance.timestamp,
    };
