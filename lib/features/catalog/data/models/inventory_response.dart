import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

part 'inventory_response.g.dart';

@JsonSerializable(includeIfNull: false)
class const InventoryResponse({
  required final String productId,
  required final int stock,
  final bool? backorderable,
  final int? etaDays,
}) {
  factory fromJson(Json json) => _$InventoryResponseFromJson(json);
  Json toJson() => _$InventoryResponseToJson(this);
}
