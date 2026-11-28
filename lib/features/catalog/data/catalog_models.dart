import 'package:json_annotation/json_annotation.dart';

import 'package:grocer_mate/core/storage/json_fields.dart';

part 'catalog_models.g.dart';

@JsonSerializable()
class const CategoryResponse({
  required final String id,
  required final String name,
  required final String icon,
}) {
  factory fromJson(Json json) => _$CategoryResponseFromJson(json);
  Json toJson() => _$CategoryResponseToJson(this);
}

@JsonSerializable(includeIfNull: false)
class const ProductResponse({
  required final String id,
  required final String title,
  required final String brand,
  required final num price,
  required final num originalPrice,
  required final num stock,
  final String? categoryId,
  final String? image,
  final List<String>? images,
  final double? rating,
  final String? description,
  final List<String>? badges,
  final Map<String, num>? nutrition,
  final List<String>? allergens,
  final List<String>? related,
}) {
  factory fromJson(Json json) => _$ProductResponseFromJson(json);
  Json toJson() => _$ProductResponseToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class const DealsResponse({
  required final List<DealResponse> items,
  final String? date,
}) {
  factory fromJson(Json json) => _$DealsResponseFromJson(json);
  Json toJson() => _$DealsResponseToJson(this);
}

@JsonSerializable()
class const DealResponse({
  required final String productId,
  required final num dealPrice,
  required final String endsAt,
}) {
  factory fromJson(Json json) => _$DealResponseFromJson(json);
  Json toJson() => _$DealResponseToJson(this);
}

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

@JsonSerializable()
class const PriceHistoryResponse({
  required final String productId,
  required final List<num> history,
}) {
  factory fromJson(Json json) => _$PriceHistoryResponseFromJson(json);
  Json toJson() => _$PriceHistoryResponseToJson(this);
}

@JsonSerializable(includeIfNull: false)
class const SuggestionsResponse({
  required final List<String> suggestions,
  final String? q,
}) {
  factory fromJson(Json json) => _$SuggestionsResponseFromJson(json);
  Json toJson() => _$SuggestionsResponseToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class const StockResponse({
  required final List<StockItem> stocks,
  final String? timestamp,
}) {
  factory fromJson(Json json) => _$StockResponseFromJson(json);
  Json toJson() => _$StockResponseToJson(this);
}

@JsonSerializable()
class const StockItem({
  required final String productId,
  required final int stock,
}) {
  factory fromJson(Json json) => _$StockItemFromJson(json);
  Json toJson() => _$StockItemToJson(this);
}
