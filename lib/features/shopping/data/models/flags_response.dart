import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

part 'flags_response.g.dart';

@JsonSerializable(includeIfNull: false)
class const FlagsResponse({
  required final String currency,
  final bool? showDeals,
  final bool? enablePriceRevalidation,
  final num? taxRate,
  final num? deliveryFee,
  final num? freeDeliveryThreshold,
  final int? searchDebounceMs,
  final bool? enableSavedForLater,
  final bool? maintenanceMode,
}) {
  factory fromJson(Json json) => _$FlagsResponseFromJson(json);
  Json toJson() => _$FlagsResponseToJson(this);
}
