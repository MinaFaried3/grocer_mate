// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderResponse _$OrderResponseFromJson(Map<String, dynamic> json) =>
    OrderResponse(
      orderId: json['orderId'] as String,
      status: json['status'] as String,
      createdAt: json['createdAt'] as String,
      currency: json['currency'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotal: json['subtotal'] as num,
      tax: json['tax'] as num,
      deliveryFee: json['deliveryFee'] as num,
      total: json['total'] as num,
    );

Map<String, dynamic> _$OrderResponseToJson(OrderResponse instance) =>
    <String, dynamic>{
      'orderId': instance.orderId,
      'status': instance.status,
      'createdAt': instance.createdAt,
      'currency': instance.currency,
      'items': instance.items.map((e) => e.toJson()).toList(),
      'subtotal': instance.subtotal,
      'tax': instance.tax,
      'deliveryFee': instance.deliveryFee,
      'total': instance.total,
    };
