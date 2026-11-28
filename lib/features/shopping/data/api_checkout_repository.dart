import 'package:grocer_mate/core/network/connectivity/offline_exception.dart';
import 'package:grocer_mate/core/network/market_api.dart';
import 'package:grocer_mate/core/storage/json_fields.dart';

import '../domain/entities/shopping.dart';
import '../domain/repositories/checkout_repository.dart';

class ApiCheckoutRepository(
  final MarketApi _api,
  final bool Function() _isOnline,
) implements CheckoutRepository {
  Future<String>? _currency;

  Future<JsonObject> flags() async => await _api.get('flags') as JsonObject;

  Future<String> _loadCurrency() async {
    try {
      return readText(await flags(), 'currency');
    } catch (_) {
      _currency = null;
      rethrow;
    }
  }

  @override
  Future<PurchaseResult> purchase(PendingPurchase purchase) async {
    if (!_isOnline()) throw const OfflineException();
    final currency = await (_currency ??= _loadCurrency());
    if (!_isOnline()) throw const OfflineException();
    final response = await _api.post(
      'purchase',
      {
        'items': [
          for (final line in purchase.lines)
            {
              'productId': line.product.id,
              'qty': line.quantity,
              'expectedPrice': line.product.price / 100,
            },
        ],
        'currency': currency,
      },
      idempotencyKey: purchase.id,
      acceptedStatuses: const {409, 422},
    );
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

  OrderReceipt _receipt(JsonObject response) => OrderReceipt(
    id: readText(response, 'orderId'),
    total: readCents(response, 'finalTotal'),
  );

  PurchaseReview _review(
    PendingPurchase purchase, {
    List<dynamic> prices = const [],
    List<dynamic> stocks = const [],
  }) {
    final currentPrices = {
      for (final JsonObject item in prices)
        readText(item, 'productId'): readCents(item, 'newPrice'),
    };
    final currentStocks = {
      for (final JsonObject item in stocks)
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

  PartialPurchase _partial(PendingPurchase purchase, JsonObject response) {
    final lines = {for (final line in purchase.lines) line.product.id: line};
    final fulfilled = <String, int>{};
    for (final JsonObject item in response['fulfilled'] as List) {
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

  Future<JsonObject> order(String id) async =>
      await _api.get('orders', id: id) as JsonObject;

  Future<JsonObject> sync(JsonObject request) => _api.post('sync', request);
}
