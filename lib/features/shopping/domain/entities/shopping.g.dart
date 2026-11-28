// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shopping.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderReceipt _$OrderReceiptFromJson(Map<String, dynamic> json) => OrderReceipt(
  id: json['id'] as String,
  total: (json['total'] as num).toInt(),
);

Map<String, dynamic> _$OrderReceiptToJson(OrderReceipt instance) =>
    <String, dynamic>{'id': instance.id, 'total': instance.total};
