import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

part 'stock_item.g.dart';

@JsonSerializable()
class const StockItem({
  required final String productId,
  required final int stock,
}) {
  factory fromJson(Json json) => _$StockItemFromJson(json);
  Json toJson() => _$StockItemToJson(this);
}
