import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

part 'purchase_item.g.dart';

@JsonSerializable(includeIfNull: false)
class const PurchaseItem({
  required final String productId,
  required final num qty,
  final num? expectedPrice,
}) {
  factory fromJson(Json json) => _$PurchaseItemFromJson(json);
  Json toJson() => _$PurchaseItemToJson(this);
}
