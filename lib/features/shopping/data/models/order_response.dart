import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

import 'order_item.dart';

part 'order_response.g.dart';

@JsonSerializable(explicitToJson: true)
class const OrderResponse({
  required final String orderId,
  required final String status,
  required final String createdAt,
  required final String currency,
  required final List<OrderItem> items,
  required final num subtotal,
  required final num tax,
  required final num deliveryFee,
  required final num total,
}) {
  factory fromJson(Json json) => _$OrderResponseFromJson(json);
  Json toJson() => _$OrderResponseToJson(this);
}
