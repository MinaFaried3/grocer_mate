import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

part 'price_change_response.g.dart';

@JsonSerializable(includeIfNull: false)
class const PriceChangeResponse({
  required final String productId,
  required final num newPrice,
  final num? oldPrice,
}) {
  factory fromJson(Json json) => _$PriceChangeResponseFromJson(json);
  Json toJson() => _$PriceChangeResponseToJson(this);
}
