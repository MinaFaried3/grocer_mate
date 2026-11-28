import 'package:grocer_mate/core/storage/json_fields.dart';

import '../domain/entities/shopping.dart';
import 'checkout_models.dart';

PurchaseRequest purchaseRequest(PendingPurchase purchase, {String? currency}) =>
    PurchaseRequest(
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

PurchaseResult decodePurchase(
  PendingPurchase purchase,
  PurchaseResponse response,
) {
  return switch (response.status) {
    'success' => _receipt(response),
    'price_changed' => _review(purchase, prices: response.changes ?? const []),
    'out_of_stock' => _review(purchase, stocks: response.items ?? const []),
    'review_required' => _review(
      purchase,
      prices: response.priceChanges ?? const [],
      stocks: response.oos ?? const [],
    ),
    'partial' => _partial(purchase, response),
    _ => throw const FormatException('Unknown purchase status.'),
  };
}

OrderReceipt _receipt(PurchaseResponse response) => OrderReceipt(
  id: requireText(response.orderId, 'orderId'),
  total: requireCents(response.finalTotal, 'finalTotal'),
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
  final changes = [
    for (final line in purchase.lines)
      if (currentPrices.containsKey(line.product.id) ||
          currentStocks.containsKey(line.product.id))
        CheckoutChange(
          productId: line.product.id,
          currentPrice: currentPrices[line.product.id] ?? line.product.price,
          available: currentStocks[line.product.id] ?? line.product.stock,
        ),
  ];
  if (changes.isEmpty) {
    throw const FormatException('Purchase review is missing changes.');
  }
  return PurchaseReview(List.unmodifiable(changes));
}

PartialPurchase _partial(PendingPurchase purchase, PurchaseResponse response) {
  final lines = {for (final line in purchase.lines) line.product.id: line};
  final fulfilled = <String, int>{};
  for (final item in response.fulfilled ?? const []) {
    final id = requireText(item.productId, 'productId');
    final quantity = requireInt(item.qty, 'qty', minimum: 1);
    final total = (fulfilled[id] ?? 0) + quantity;
    if (lines[id] == null || total > lines[id]!.quantity) {
      throw const FormatException('Invalid fulfilled quantity.');
    }
    fulfilled[id] = total;
  }
  if (fulfilled.isEmpty) {
    throw const FormatException('No items were fulfilled.');
  }
  // Restore every unfulfilled item, including lines omitted from example responses.
  final missing = [
    for (final line in purchase.lines)
      if ((fulfilled[line.product.id] ?? 0) < line.quantity)
        line.withQuantity(line.quantity - (fulfilled[line.product.id] ?? 0)),
  ];
  return PartialPurchase(
    List.unmodifiable(missing),
    receipt: response.orderId != null && response.finalTotal != null
        ? _receipt(response)
        : null,
    note: response.note,
  );
}
