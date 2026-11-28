import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

import '../domain/entities/shopping.dart';

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

  factory fromPurchase(PendingPurchase purchase, {String? currency}) => .new(
    items: [
      for (final line in purchase.lines)
        PurchaseItem(
          productId: line.product.id,
          qty: line.quantity,
          expectedPrice: line.product.price / 100,
        ),
    ],
    currency: currency,
  );
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

  PurchaseResult toResult(PendingPurchase purchase) => switch (status) {
    'success' => _receipt(),
    'price_changed' => _review(purchase, prices: changes ?? const []),
    'out_of_stock' => _review(purchase, stocks: items ?? const []),
    'review_required' => _review(
      purchase,
      prices: priceChanges ?? const [],
      stocks: oos ?? const [],
    ),
    'partial' => _partial(purchase),
    _ => throw const FormatException('Unknown purchase status.'),
  };

  OrderReceipt _receipt() => OrderReceipt(
    id: requireText(orderId, 'orderId'),
    total: requireCents(finalTotal, 'finalTotal'),
  );

  PurchaseReview _review(
    PendingPurchase purchase, {
    List<PriceChangeResponse> prices = const [],
    List<StockChangeResponse> stocks = const [],
  }) {
    final currentPrices = {
      for (final item in prices)
        requireText(item.productId, 'productId'): requireCents(
          item.newPrice,
          'newPrice',
        ),
    };
    final currentStocks = {
      for (final item in stocks)
        requireText(item.productId, 'productId'): requireInt(
          item.available,
          'available',
        ),
    };
    final updates = [
      for (final line in purchase.lines)
        if (currentPrices.containsKey(line.product.id) ||
            currentStocks.containsKey(line.product.id))
          CheckoutChange(
            productId: line.product.id,
            currentPrice: currentPrices[line.product.id] ?? line.product.price,
            available: currentStocks[line.product.id] ?? line.product.stock,
          ),
    ];
    if (updates.isEmpty) {
      throw const FormatException('Purchase review is missing changes.');
    }
    return PurchaseReview(List.unmodifiable(updates));
  }

  PartialPurchase _partial(PendingPurchase purchase) {
    final lines = {for (final line in purchase.lines) line.product.id: line};
    final completed = <String, int>{};
    for (final item in fulfilled ?? const []) {
      final id = requireText(item.productId, 'productId');
      final quantity = requireInt(item.qty, 'qty', minimum: 1);
      final total = (completed[id] ?? 0) + quantity;
      if (lines[id] == null || total > lines[id]!.quantity) {
        throw const FormatException('Invalid fulfilled quantity.');
      }
      completed[id] = total;
    }
    if (completed.isEmpty) {
      throw const FormatException('No items were fulfilled.');
    }
    // Restore every unfulfilled item, including lines omitted from example responses.
    final unfulfilled = [
      for (final line in purchase.lines)
        if ((completed[line.product.id] ?? 0) < line.quantity)
          line.withQuantity(line.quantity - (completed[line.product.id] ?? 0)),
    ];
    return PartialPurchase(
      List.unmodifiable(unfulfilled),
      receipt: orderId != null && finalTotal != null ? _receipt() : null,
      note: note,
    );
  }
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
