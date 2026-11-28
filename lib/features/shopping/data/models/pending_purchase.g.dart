// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_purchase.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PendingPurchase _$PendingPurchaseFromJson(Map<String, dynamic> json) =>
    PendingPurchase(
      json['id'] as String,
      (json['lines'] as List<dynamic>)
          .map((e) => CartLine.fromJson(e as Map<String, dynamic>))
          .toList(),
      attempted: json['attempted'] as bool? ?? false,
    );

Map<String, dynamic> _$PendingPurchaseToJson(PendingPurchase instance) =>
    <String, dynamic>{
      'id': instance.id,
      'lines': instance.lines.map((e) => e.toJson()).toList(),
      'attempted': instance.attempted,
    };
