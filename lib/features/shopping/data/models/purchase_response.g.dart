// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PurchaseResponse _$PurchaseResponseFromJson(Map<String, dynamic> json) =>
    PurchaseResponse(
      status: json['status'] as String,
      orderId: json['orderId'] as String?,
      finalTotal: json['finalTotal'] as num?,
      note: json['note'] as String?,
      changes: (json['changes'] as List<dynamic>?)
          ?.map((e) => PriceChangeResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => StockChangeResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      priceChanges: (json['priceChanges'] as List<dynamic>?)
          ?.map((e) => PriceChangeResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      oos: (json['oos'] as List<dynamic>?)
          ?.map((e) => StockChangeResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      fulfilled: (json['fulfilled'] as List<dynamic>?)
          ?.map((e) => PurchaseItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      missing: (json['missing'] as List<dynamic>?)
          ?.map((e) => PurchaseItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PurchaseResponseToJson(PurchaseResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'orderId': ?instance.orderId,
      'finalTotal': ?instance.finalTotal,
      'note': ?instance.note,
      'changes': ?instance.changes?.map((e) => e.toJson()).toList(),
      'items': ?instance.items?.map((e) => e.toJson()).toList(),
      'priceChanges': ?instance.priceChanges?.map((e) => e.toJson()).toList(),
      'oos': ?instance.oos?.map((e) => e.toJson()).toList(),
      'fulfilled': ?instance.fulfilled?.map((e) => e.toJson()).toList(),
      'missing': ?instance.missing?.map((e) => e.toJson()).toList(),
    };
