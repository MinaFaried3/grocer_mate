import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

part 'order_item.g.dart';

@JsonSerializable()
class const OrderItem({
  required final String productId,
  required final int qty,
  required final num unitPrice,
}) {
  factory fromJson(Json json) => _$OrderItemFromJson(json);
  Json toJson() => _$OrderItemToJson(this);
}
