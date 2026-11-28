import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

part 'price_history_response.g.dart';

@JsonSerializable()
class const PriceHistoryResponse({
  required final String productId,
  required final List<num> history,
}) {
  factory fromJson(Json json) => _$PriceHistoryResponseFromJson(json);
  Json toJson() => _$PriceHistoryResponseToJson(this);
}
