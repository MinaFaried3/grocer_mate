import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

import 'deal_response.dart';

part 'deals_response.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class const DealsResponse({
  required final List<DealResponse> items,
  final String? date,
}) {
  factory fromJson(Json json) => _$DealsResponseFromJson(json);
  Json toJson() => _$DealsResponseToJson(this);
}
