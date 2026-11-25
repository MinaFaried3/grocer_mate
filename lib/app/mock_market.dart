import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';

import '../core/network/connection.dart';
import '../core/storage/json_store.dart';
import '../features/catalog/domain/catalog.dart';
import '../features/shopping/domain/shopping.dart';

enum CheckoutScenario {
  normal('Normal checkout'),
  prices('Price changes'),
  stock('Stock changes'),
  mixed('Price and stock changes');

  const CheckoutScenario(this.label);
  final String label;
}

class MockMarket implements CheckoutRepository {
  MockMarket(this.store, this.connection, this.bundle);

  static const catalogAsset = 'assets/catalog.json';
  static const _serverKey = 'mock_market_v1';

  final JsonStore store;
  final Connection connection;
  final AssetBundle bundle;
  Future<Map<String, dynamic>>? _seed;
  CheckoutScenario scenario = CheckoutScenario.normal;

  Future<Map<String, dynamic>> _loadSeed() async {
    try {
      return jsonDecode(await bundle.loadString(catalogAsset))
          as Map<String, dynamic>;
    } catch (_) {
      _seed = null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> catalog() async {
    await _delay(const Duration(milliseconds: 260));
    final seed = await (_seed ??= _loadSeed());
    final market = await _readServer();
    final availability = _availability(market);
    return {
      'categories': seed['categories'],
      'products': [
        for (final product
            in (seed['products'] as List).cast<Map<String, dynamic>>())
          {...product, ...?availability[product['id']]},
      ],
    };
  }

  @override
  Future<PurchaseResult> purchase(PendingPurchase purchase) async {
    await _delay(const Duration(milliseconds: 320));
    final market = await _readServer();
    final receipts = Map<String, dynamic>.from(market['receipts']);
    final previousReceipt = receipts[purchase.id];
    if (previousReceipt != null) return OrderReceipt.fromJson(previousReceipt);

    final seed = await (_seed ??= _loadSeed());
    final products = {
      for (final json in seed['products'])
        json['id'] as String: Product.fromJson(json),
    };
    final availability = _availability(market);
    int priceFor(String id, int fallback) =>
        availability[id]?['price'] ?? products[id]?.price ?? fallback;
    int stockFor(String id) =>
        availability[id]?['stock'] ?? products[id]?.stock ?? 0;

    final armed = scenario;
    if (armed != CheckoutScenario.normal) {
      _applyScenario(armed, purchase.lines, availability, priceFor, stockFor);
    }
    final changes = <CheckoutChange>[];
    for (final line in purchase.lines) {
      final id = line.product.id;
      final change = CheckoutChange(
        productId: id,
        currentPrice: priceFor(id, line.product.price),
        available: stockFor(id),
      );
      if (change.priceChanged(line) || change.stockChanged(line)) {
        changes.add(change);
      }
    }
    final PurchaseResult result;
    if (changes.isEmpty) {
      for (final line in purchase.lines) {
        final id = line.product.id;
        availability[id] = {
          'price': priceFor(id, line.product.price),
          'stock': stockFor(id) - line.quantity,
        };
      }
      final receipt = OrderReceipt(
        id: 'GM-${1001 + receipts.length}',
        total: OrderTotals.forLines(purchase.lines).total,
      );
      receipts[purchase.id] = receipt.toJson();
      result = receipt;
    } else {
      result = PurchaseReview(List.unmodifiable(changes));
      if (armed == CheckoutScenario.normal) return result;
    }

    await store.write(_serverKey, {
      'availability': availability,
      'receipts': receipts,
    });
    if (scenario == armed) scenario = CheckoutScenario.normal;
    return result;
  }

  Future<void> _delay(Duration duration) async {
    if (!connection.online) throw const OfflineException();
    await Future<void>.delayed(duration);
    if (!connection.online) throw const OfflineException();
  }

  Future<Map<String, dynamic>> _readServer() async =>
      await store.read(_serverKey) ?? {'availability': {}, 'receipts': {}};

  Map<String, Map<String, int>> _availability(Map<String, dynamic> market) => {
    for (final entry in (market['availability'] as Map).entries)
      entry.key: Map<String, int>.from(entry.value),
  };

  void _applyScenario(
    CheckoutScenario type,
    List<CartLine> lines,
    Map<String, Map<String, int>> availability,
    int Function(String id, int fallback) priceFor,
    int Function(String id) stockFor,
  ) {
    final priceEdit =
        type == CheckoutScenario.prices || type == CheckoutScenario.mixed;
    final stockEdit =
        type == CheckoutScenario.stock || type == CheckoutScenario.mixed;
    for (final (index, line) in lines.take(2).indexed) {
      final id = line.product.id;
      var price = priceFor(id, line.product.price);
      var stock = stockFor(id);
      if (priceEdit && (index == 0 || !stockEdit)) {
        price += index == 0 ? 10 : -5;
      }
      if (stockEdit && (index == 1 || !priceEdit || lines.length == 1)) {
        stock = index == 1 ? 0 : math.min(stock, line.quantity - 1);
      }
      availability[id] = {'price': price, 'stock': stock};
    }
  }
}
