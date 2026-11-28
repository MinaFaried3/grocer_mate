// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PurchaseRequest _$PurchaseRequestFromJson(Map<String, dynamic> json) =>
    PurchaseRequest(
      items: (json['items'] as List<dynamic>)
          .map((e) => PurchaseItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      currency: json['currency'] as String?,
    );

Map<String, dynamic> _$PurchaseRequestToJson(PurchaseRequest instance) =>
    <String, dynamic>{
      'items': instance.items.map((e) => e.toJson()).toList(),
      'currency': ?instance.currency,
    };
