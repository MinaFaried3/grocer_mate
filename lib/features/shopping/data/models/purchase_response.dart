import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/shopping.dart';
import 'price_change_response.dart';
import 'purchase_item.dart';
import 'stock_change_response.dart';

part 'purchase_response.g.dart';

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
