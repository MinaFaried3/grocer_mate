import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

part 'deal_response.g.dart';

@JsonSerializable()
class const DealResponse({
  required final String productId,
  required final num dealPrice,
  required final String endsAt,
}) {
  factory fromJson(Json json) => _$DealResponseFromJson(json);
  Json toJson() => _$DealResponseToJson(this);
}
