import 'package:json_annotation/json_annotation.dart';

import 'package:grocer_mate/core/storage/json_fields.dart';

part 'checkout_models.g.dart';

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

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class const PurchaseRequest({
  required final List<PurchaseItem> items,
  final String? currency,
}) {
  factory fromJson(Json json) => _$PurchaseRequestFromJson(json);
  Json toJson() => _$PurchaseRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class const PurchaseItem({
  required final String productId,
  required final num qty,
  final num? expectedPrice,
}) {
  factory fromJson(Json json) => _$PurchaseItemFromJson(json);
  Json toJson() => _$PurchaseItemToJson(this);
}

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class const PurchaseResponse({
  required final String status,
  final String? orderId,
  final num? finalTotal,
  final String? note,
  final List<PriceChangeResponse>? changes,
  final List<StockChangeResponse>? items,
  final List<PriceChangeResponse>? priceChanges,
  final List<StockChangeResponse>? oos,
  final List<PurchaseItem>? fulfilled,
  final List<PurchaseItem>? missing,
}) {
  factory fromJson(Json json) => _$PurchaseResponseFromJson(json);
  Json toJson() => _$PurchaseResponseToJson(this);
}

@JsonSerializable(includeIfNull: false)
class const PriceChangeResponse({
  required final String productId,
  required final num newPrice,
  final num? oldPrice,
}) {
  factory fromJson(Json json) => _$PriceChangeResponseFromJson(json);
  Json toJson() => _$PriceChangeResponseToJson(this);
}

@JsonSerializable()
class const StockChangeResponse({
  required final String productId,
  required final num available,
}) {
  factory fromJson(Json json) => _$StockChangeResponseFromJson(json);
  Json toJson() => _$StockChangeResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class const OrderResponse({
  required final String orderId,
  required final String status,
  required final String createdAt,
  required final String currency,
  required final List<OrderItem> items,
  required final num subtotal,
  required final num tax,
  required final num deliveryFee,
  required final num total,
}) {
  factory fromJson(Json json) => _$OrderResponseFromJson(json);
  Json toJson() => _$OrderResponseToJson(this);
}

@JsonSerializable()
class const OrderItem({
  required final String productId,
  required final int qty,
  required final num unitPrice,
}) {
  factory fromJson(Json json) => _$OrderItemFromJson(json);
  Json toJson() => _$OrderItemToJson(this);
}

@JsonSerializable(explicitToJson: true)
class const SyncRequest({
  required final int baseVersion,
  required final List<SyncMutation> mutations,
}) {
  factory fromJson(Json json) => _$SyncRequestFromJson(json);
  Json toJson() => _$SyncRequestToJson(this);
}

@JsonSerializable(explicitToJson: true)
class const SyncMutation({
  required final String op,
  required final String idempotencyKey,
  required final PurchaseRequest payload,
}) {
  factory fromJson(Json json) => _$SyncMutationFromJson(json);
  Json toJson() => _$SyncMutationToJson(this);
}

@JsonSerializable()
class const SyncResponse({
  required final String status,
  required final int newVersion,
}) {
  factory fromJson(Json json) => _$SyncResponseFromJson(json);
  Json toJson() => _$SyncResponseToJson(this);
}
