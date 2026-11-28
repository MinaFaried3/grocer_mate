part of 'mock_market.dart';

extension _MockPurchase on MockMarket {
  Future<Json> _purchase(
    Json market,
    Json body,
    String? key, {
    String scenario = 'normal',
  }) async {
    if (key != null) {
      if (market['purchases'][key] case final Json previous) {
        return previous;
      }
      if (market['receipts'][key] case final Json previous) {
        return {
          'status': 'success',
          'orderId': readText(previous, 'id'),
          'finalTotal': readInt(previous, 'total') / 100,
        };
      }
    }

    final flags = await _fixture('flags') as Json;
    if (flags['maintenanceMode'] == true) {
      throw const MockMarketException(
        503,
        'The market is temporarily unavailable.',
      );
    }
    final currency = body['currency'] ?? flags['currency'];
    if (currency != flags['currency']) {
      throw const FormatException('Unsupported currency.');
    }
    final items = body['items'];
    if (items is! List || items.isEmpty) {
      throw const FormatException('Expected purchase items.');
    }
    final lines = <String, ({int qty, int? expectedPrice})>{};
    for (final item in items) {
      if (item is! Json) {
        throw const FormatException('Invalid purchase item.');
      }
      final id = readText(item, 'productId').toLowerCase();
      final qty = readInt(item, 'qty', minimum: 1);
      final price = item.containsKey('expectedPrice')
          ? readCents(item, 'expectedPrice')
          : null;
      final previous = lines[id];
      if (previous != null && previous.expectedPrice != price) {
        throw const FormatException('Conflicting prices for the same product.');
      }
      lines[id] = (qty: qty + (previous?.qty ?? 0), expectedPrice: price);
    }

    final productById = {
      for (final item in await _products(market)) item['id']: item,
    };
    final deals = await _dealsToday(market);
    final now = DateTime.now().toUtc();
    final dailyPrices = {
      if (flags['showDeals'] == true)
        for (final item in (deals['items'] as List).cast<Json>())
          if (DateTime.parse(readText(item, 'endsAt')).isAfter(now))
            readText(item, 'productId'): readCents(item, 'dealPrice'),
    };
    final purchaseFixture = await _fixture('purchase') as Json;
    final rules = purchaseFixture['scenarios'][scenario] as Json?;
    if (rules == null) {
      throw const FormatException('Unknown checkout scenario.');
    }
    final priceDeltas = _changesForCart(
      lines.keys.toList(),
      rules['priceChanges'],
    );
    final stockTargets = _changesForCart(
      lines.keys.toList(),
      rules['stockChanges'],
    );
    final availability = market['availability'] as Json;
    final changes = <Json>[];
    final outOfStock = <Json>[];
    final fulfilled = <Json>[];
    final missing = <Json>[];
    final orderLines = <Json>[];
    var subtotal = 0;
    for (final entry in lines.entries) {
      final id = entry.key;
      final (:qty, :expectedPrice) = entry.value;
      final product = productById[id];
      var stock = product == null ? 0 : readInt(product, 'stock');
      var price = product == null
          ? expectedPrice ?? 0
          : readCents(product, 'price');
      price = dailyPrices[id] ?? price;
      if (priceDeltas[id]?['delta'] case final num delta when product != null) {
        final next = price + (delta * 100).round();
        price = next < 0 ? 0 : next;
        _updateAvailability(availability, id, 'price', price);
      }
      if (stockTargets[id]?['available'] case final int target
          when product != null) {
        stock = stock.clamp(0, target);
        _updateAvailability(availability, id, 'stock', stock);
      }
      if (product != null &&
          flags['enablePriceRevalidation'] == true &&
          expectedPrice != null &&
          expectedPrice != price) {
        changes.add({
          'productId': id,
          'oldPrice': expectedPrice / 100,
          'newPrice': price / 100,
        });
      }
      if (stock < qty) {
        outOfStock.add({'productId': id, 'available': stock});
        missing.add({'productId': id, 'qty': qty - stock});
      }
      final availableQty = qty.clamp(0, stock);
      if (availableQty > 0) {
        fulfilled.add({'productId': id, 'qty': availableQty});
        orderLines.add({
          'productId': id,
          'qty': availableQty,
          'unitPrice': price / 100,
        });
        subtotal += price * availableQty;
      }
    }
    if (changes.isNotEmpty) {
      if (outOfStock.isNotEmpty) {
        return {
          'status': 'review_required',
          'priceChanges': changes,
          'oos': outOfStock,
        };
      }
      return {'status': 'price_changed', 'changes': changes};
    }
    if (outOfStock.isNotEmpty &&
        (rules['allowPartial'] != true || fulfilled.isEmpty)) {
      return {'status': 'out_of_stock', 'items': outOfStock};
    }

    for (final line in fulfilled) {
      final id = readText(line, 'productId');
      final stock =
          (availability[id] as Map?)?['stock'] as int? ??
          readInt(productById[id]!, 'stock');
      _updateAvailability(
        availability,
        id,
        'stock',
        stock - readInt(line, 'qty'),
      );
    }
    final orders = market['orders'] as Json;
    final receipts = market['receipts'] as Json;
    final orderId =
        'o_${readInt(purchaseFixture, 'orderIdStart') + orders.length + receipts.length}';
    final tax = (subtotal * (flags['taxRate'] as num)).round();
    final delivery =
        subtotal == 0 || subtotal >= readCents(flags, 'freeDeliveryThreshold')
        ? 0
        : readCents(flags, 'deliveryFee');
    final total = (subtotal + tax + delivery) / 100;
    orders[orderId] = {
      'orderId': orderId,
      'status': 'placed',
      'createdAt': now.toIso8601String(),
      'currency': currency,
      'items': orderLines,
      'subtotal': subtotal / 100,
      'tax': tax / 100,
      'deliveryFee': delivery / 100,
      'total': total,
    };
    final response = {
      'status': missing.isEmpty ? 'success' : 'partial',
      'orderId': orderId,
      'finalTotal': total,
      if (missing.isNotEmpty) ...{
        'fulfilled': fulfilled,
        'missing': missing,
        'note': rules['note'],
      },
    };
    if (key != null) market['purchases'][key] = response;
    return response;
  }

  Map<String, Json> _changesForCart(
    List<String> ids,
    List<dynamic>? changes,
  ) {
    final rules = changes?.cast<Json>() ?? const <Json>[];
    final result = <String, Json>{};
    for (final rule in rules) {
      final id = readText(rule, 'productId');
      if (ids.contains(id)) result[id] = rule;
    }
    for (final rule in rules) {
      if (result.containsValue(rule)) continue;
      final index = readInt(rule, 'fallbackIndex');
      if (index >= ids.length) continue;
      final preferred = ids[index];
      final id = result.containsKey(preferred)
          ? ids.where((id) => !result.containsKey(id)).firstOrNull
          : preferred;
      if (id != null) result[id] = rule;
    }
    return result;
  }

  void _updateAvailability(
    Json availability,
    String id,
    String field,
    int value,
  ) {
    availability[id] = {...?(availability[id] as Json?), field: value};
  }

  Future<Json> _sync(Json market, Json body) async {
    final seed = await _fixture('sync') as Json;
    final version = market['version'] as int? ?? readInt(seed, 'baseVersion');
    final base = readInt(body, 'baseVersion');
    final mutations = body['mutations'];
    if (mutations is! List) {
      throw const FormatException('Expected sync mutations.');
    }
    final synced = market['synced'] as Json;
    final pending = <({String key, Json payload})>[];
    final keys = <String>{};
    for (final mutation in mutations) {
      if (mutation is! Json ||
          mutation['op'] != 'purchase' ||
          mutation['payload'] is! Json) {
        throw const FormatException('Invalid sync mutation.');
      }
      final key = readText(mutation, 'idempotencyKey');
      if (synced[key] != true && keys.add(key)) {
        pending.add((key: key, payload: mutation['payload'] as Json));
      }
    }
    if (pending.isEmpty) return {'status': 'ok', 'newVersion': version};
    if (base != version) {
      throw const MockMarketException(409, 'Sync version has changed.');
    }
    for (final (:key, :payload) in pending) {
      final result = await _purchase(market, payload, key);
      if (result['status'] != 'success') {
        throw const MockMarketException(
          409,
          'A purchase needs review before syncing.',
        );
      }
      synced[key] = true;
    }
    market['version'] = version + 1;
    await _storage.write(MockMarket._marketKey, market);
    return {'status': 'ok', 'newVersion': version + 1};
  }
}
