import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

part 'stock_change_response.g.dart';

@JsonSerializable()
class const StockChangeResponse({
  required final String productId,
  required final num available,
}) {
  factory fromJson(Json json) => _$StockChangeResponseFromJson(json);
  Json toJson() => _$StockChangeResponseToJson(this);
}
