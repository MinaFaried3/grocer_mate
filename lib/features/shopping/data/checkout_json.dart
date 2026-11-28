import 'package:grocer_mate/core/storage/json_fields.dart';

import '../domain/entities/shopping.dart';

Json encodePurchase(PendingPurchase purchase, {String? currency}) => {
  'items': [
    for (final line in purchase.lines)
      {
        'productId': line.product.id,
        'qty': line.quantity,
        'expectedPrice': line.product.price / 100,
      },
  ],
  'currency': ?currency,
};

PurchaseResult decodePurchase(PendingPurchase purchase, Json response) {
  return switch (response['status']) {
    'success' => _receipt(response),
    'price_changed' => _review(purchase, prices: response['changes']),
    'out_of_stock' => _review(purchase, stocks: response['items']),
    'review_required' => _review(
      purchase,
      prices: response['priceChanges'],
      stocks: response['oos'],
    ),
    'partial' => _partial(purchase, response),
    _ => throw const FormatException('Unknown purchase status.'),
  };
}

OrderReceipt _receipt(Json response) => OrderReceipt(
  id: readText(response, 'orderId'),
  total: readCents(response, 'finalTotal'),
);

PurchaseReview _review(
  PendingPurchase purchase, {
  List<dynamic> prices = const [],
  List<dynamic> stocks = const [],
}) {
  final currentPrices = {
    for (final Json item in prices)
      readText(item, 'productId'): readCents(item, 'newPrice'),
  };
  final currentStocks = {
    for (final Json item in stocks)
      readText(item, 'productId'): readInt(item, 'available'),
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

PartialPurchase _partial(PendingPurchase purchase, Json response) {
  final lines = {for (final line in purchase.lines) line.product.id: line};
  final fulfilled = <String, int>{};
  for (final Json item in response['fulfilled'] as List) {
    final id = readText(item, 'productId');
    final quantity = readInt(item, 'qty', minimum: 1);
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
    receipt:
        response.containsKey('orderId') && response.containsKey('finalTotal')
        ? _receipt(response)
        : null,
    note: response['note'] as String?,
  );
}
