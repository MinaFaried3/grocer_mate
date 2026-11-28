import 'package:grocer_mate/core/network/endpoint_exception.dart';
import 'package:grocer_mate/core/network/endpoints.dart';
import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:grocer_mate/core/storage/market_store.dart';
import 'package:grocer_mate/core/storage/mock_json_reader.dart';
import 'package:grocer_mate/features/catalog/data/sources/mock_catalog_remote_ds.dart';

import '../../domain/entities/checkout_settings.dart';
import '../models/purchase_request.dart';
import '../models/purchase_response.dart';
import 'checkout_remote_source.dart';

class MockCheckoutRemoteDS with MockJsonReader implements CheckoutRemoteSource {
  MockCheckoutRemoteDS(
    this.loadMockAsset,
    this._store,
    this._catalog, {
    required this.settings,
  });

  @override
  final Future<String> Function(String) loadMockAsset;
  final MarketStore _store;
  final CheckoutSettings settings;
  final MockCatalogRemoteDS _catalog;
  Future<void> _writes = Future.value();

  //------------ Checkout Remote Source ---------------
  @override
  Future<PurchaseResponse> purchase(
    PurchaseRequest request, {
    required String idempotencyKey,
  }) async => PurchaseResponse.fromJson(
    await purchasePayload(request.toJson(), key: idempotencyKey),
  );

  //------------ Mock API Payloads ---------------
  Future<Json> flags() => readMockJson<Json>(Endpoints.flags);

  Future<Json> order(String id) async {
    final market = await _store.read();
    final orders = await readMockJson<Json>(Endpoints.orders);
    final key = id.toLowerCase();
    return market['orders']?[key] ??
        orders[key] ??
        (throw const EndpointException(404, 'Order not found.'));
  }

  Future<Json> purchasePayload(Json body, {String? key}) => _write(() async {
    final market = await _readForWrite();
    final scenario = settings.scenario;
    // Check if this idempotency key already has a saved purchase or receipt.
    final hasSavedAttempt =
        key != null &&
        (market['purchases'][key] != null || market['receipts'][key] != null);
    final result = await _applyPurchase(market, body, key, scenario: scenario);
    await _store.write(market);
    // Reset one-shot checkout scenario after a fresh purchase attempt completes.
    final shouldResetScenario =
        !hasSavedAttempt && settings.scenario == scenario;
    if (shouldResetScenario) settings.scenario = 'normal';
    return result;
  });

  Future<Json> sync(Json body) =>
      _write(() async => _sync(await _readForWrite(), body));

  //------------ Serialized Market Writes ---------------
  Future<Json> _write(Future<Json> Function() update) {
    final operation = _writes.then((_) => update());
    _writes = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<Json> _readForWrite() async {
    final stored = await _store.read();
    return {
      ...stored,
      for (final field in [
        'availability',
        'receipts',
        'purchases',
        'orders',
        'synced',
      ])
        field: Json.from(stored[field] as Map? ?? const {}),
    };
  }

  //------------ Batch Sync ---------------
  Future<Json> _sync(Json market, Json body) async {
    //------------ Read the Sync Request and Current Version ---------------
    final seed = await readMockJson<Json>(Endpoints.sync);
    final version = market['version'] as int? ?? readInt(seed, 'baseVersion');
    final base = readInt(body, 'baseVersion');
    final mutations = body['mutations'];
    if (mutations is! List) {
      throw const FormatException('Expected sync mutations.');
    }

    //------------ Collect Unprocessed Purchases ---------------
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

    //------------ Validate the Batch Version ---------------
    if (pending.isEmpty) return {'status': 'ok', 'newVersion': version};
    if (base != version) {
      throw const EndpointException(409, 'Sync version has changed.');
    }

    //------------ Apply and Save the Batch ---------------
    for (final (:key, :payload) in pending) {
      final result = await _applyPurchase(market, payload, key);
      if (result['status'] != 'success') {
        throw const EndpointException(
          409,
          'A purchase needs review before syncing.',
        );
      }
      synced[key] = true;
    }
    market['version'] = version + 1;
    await _store.write(market);
    return {'status': 'ok', 'newVersion': version + 1};
  }

  //------------ Purchase Processing ---------------
  Future<Json> _applyPurchase(
    Json market,
    Json body,
    String? key, {
    String scenario = 'normal',
  }) async {
    //------------ Replay a Previous Purchase ---------------
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

    //------------ Validate the Request ---------------
    final flags = await readMockJson<Json>(Endpoints.flags);
    if (flags['maintenanceMode'] == true) {
      throw const EndpointException(
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

    //------------ Load Prices, Stock, and Scenario Rules ---------------
    final availability = market['availability'] as Json;
    final productById = {
      for (final item in await _catalog.productsWithAvailability(availability))
        item['id']: item,
    };
    final deals = await _catalog.dealsWithAvailability(availability);
    final now = DateTime.now().toUtc();
    final dailyPrices = {
      if (flags['showDeals'] == true)
        for (final item in (deals['items'] as List).cast<Json>())
          if (DateTime.parse(readText(item, 'endsAt')).isAfter(now))
            readText(item, 'productId'): readCents(item, 'dealPrice'),
    };
    final purchaseMock = await readMockJson<Json>(Endpoints.purchase);
    final rules = purchaseMock['scenarios'][scenario] as Json?;
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

    //------------ Calculate Line Changes and Fulfillment ---------------
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
      // Record price change when price revalidation is enabled and price differs.
      final isPriceRevalidationEnabled =
          product != null && flags['enablePriceRevalidation'] == true;
      final hasPriceDifference =
          expectedPrice != null && expectedPrice != price;
      if (isPriceRevalidationEnabled && hasPriceDifference) {
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

    //------------ Return Changes for Review ---------------
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
    // Return out-of-stock review when partial orders are disabled or nothing can be fulfilled.
    final cannotFulfillPartially =
        rules['allowPartial'] != true || fulfilled.isEmpty;
    if (outOfStock.isNotEmpty && cannotFulfillPartially) {
      return {'status': 'out_of_stock', 'items': outOfStock};
    }

    //------------ Deduct Fulfilled Stock ---------------
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

    //------------ Record the Order and Idempotent Response ---------------
    final orders = market['orders'] as Json;
    final receipts = market['receipts'] as Json;
    final orderId =
        'o_${readInt(purchaseMock, 'orderIdStart') + orders.length + receipts.length}';
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

  Map<String, Json> _changesForCart(List<String> ids, List<dynamic>? changes) {
    final rules = changes?.cast<Json>() ?? const <Json>[];
    final result = <String, Json>{};

    //------------ Match Rules by Product ID ---------------
    for (final rule in rules) {
      final id = readText(rule, 'productId');
      if (ids.contains(id)) result[id] = rule;
    }

    //------------ Apply Unmatched Rules by Cart Position ---------------
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
}
