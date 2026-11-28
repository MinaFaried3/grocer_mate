import 'dart:convert';

import '../network/endpoints.dart';
import '../storage/json_fields.dart';
import '../storage/local_storage.dart';

part 'mock_purchase.dart';

const demoAssetDirectory = 'assets/mock_api';

class MockMarket {
  MockMarket(
    this._storage,
    this._loadAsset, {
    this.checkoutScenario = 'normal',
  });

  final LocalStorage _storage;
  final Future<String> Function(String) _loadAsset;
  final _fixtures = <String, Future<dynamic>>{};
  String checkoutScenario;
  Future<void> _writes = Future.value();

  static const _marketKey = 'local_market_v1';

  Future<dynamic> _fixture(String endpoint) =>
      _fixtures.putIfAbsent(endpoint, () async {
        try {
          return jsonDecode(
            await _loadAsset('$demoAssetDirectory/$endpoint.json'),
          );
        } catch (_) {
          _fixtures.remove(endpoint);
          rethrow;
        }
      });

  Future<Json> _readMarket() async => await _storage.read(_marketKey) ?? {};

  Future<List<Json>> _products(Json market) async {
    final seed = (await _fixture(Endpoints.products) as List).cast<Json>();
    final availability = market['availability'] as Map? ?? const {};
    return [
      for (final product in seed)
        _withAvailability(
          product,
          availability[product['id']] as Map? ?? const {},
        ),
    ];
  }

  Json _withAvailability(Json product, Map changes) => {
    ...product,
    if (changes['price'] case final int cents) 'price': cents / 100,
    if (changes['stock'] case final int stock) 'stock': stock,
  };

  Future<List<dynamic>> categories() async =>
      await _fixture(Endpoints.categories) as List;

  Future<Json> flags() async => await _fixture(Endpoints.flags) as Json;

  Future<Json> brands([String? category]) async {
    final brands = await _fixture(Endpoints.brands) as Json;
    final id = category?.trim().toLowerCase();
    return id == null || id.isEmpty ? brands : {id: brands[id] ?? <String>[]};
  }

  Future<Json> products({
    String? category,
    String? brand,
    String? search,
    int page = 1,
    int pageSize = 10,
  }) async {
    if (page < 1 || pageSize < 1) {
      throw const FormatException('Expected positive pagination values.');
    }
    final categoryId = category?.trim().toLowerCase() ?? '';
    final brandName = brand?.trim().toLowerCase() ?? '';
    final words = (search?.trim().toLowerCase() ?? '').split(RegExp(r'\s+'));
    final products = await _products(await _readMarket());
    final matching = products.where((product) {
      // Check category, brand, and search query filters for each product.
      final matchesCategory =
          categoryId.isEmpty || product['categoryId'] == categoryId;
      final matchesBrand =
          brandName.isEmpty ||
          (product['brand'] as String).toLowerCase() == brandName;
      final matchesSearch = words.every(
        (product['title'] as String).toLowerCase().contains,
      );
      return matchesCategory && matchesBrand && matchesSearch;
    }).toList();
    return {
      'data': page - 1 > matching.length ~/ pageSize
          ? <Json>[]
          : matching.skip((page - 1) * pageSize).take(pageSize).toList(),
      'page': page,
      'pageSize': pageSize,
      'total': matching.length,
      'sort': 'popularity_desc',
    };
  }

  Future<Json> product(String id) => _productData(Endpoints.product, id);
  Future<Json> inventory(String id) => _productData(Endpoints.inventory, id);
  Future<Json> priceHistory(String id) =>
      _productData(Endpoints.priceHistory, id);
  Future<Json> dealsOfDay() async => _dealsToday(await _readMarket());

  Future<Json> suggestions(String? input) async {
    final q = input?.trim().toLowerCase() ?? '';
    final words = await _fixture(Endpoints.suggest) as List;
    final products = await _products(await _readMarket());
    final candidates = {
      ...words.cast<String>(),
      for (final product in products)
        (product['title'] as String).split(' (').first.toLowerCase(),
    };
    return {
      'q': q,
      'suggestions': q.isEmpty
          ? <String>[]
          : candidates.where((text) => text.startsWith(q)).take(8).toList(),
    };
  }

  Future<Json> checkStock(String? input) async {
    final seed = await _fixture(Endpoints.stockCheck) as Json;
    final ids =
        (input?.split(',') ?? (seed['defaultIds'] as List).cast<String>())
            .map((id) => id.trim().toLowerCase())
            .toSet();
    final byId = {
      for (final product in await _products(await _readMarket()))
        product['id']: product,
    };
    return {
      'stocks': [
        for (final id in ids)
          if (byId[id] case final product?)
            {'productId': id, 'stock': product['stock']},
      ],
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
  }

  Future<Json> order(String id) async {
    final market = await _readMarket();
    final orders = await _fixture(Endpoints.orders) as Json;
    final key = id.toLowerCase();
    return market['orders']?[key] ??
        orders[key] ??
        (throw const MockMarketException(404, 'Order not found.'));
  }

  Future<Json> purchase(Json body, {String? key}) => _write(() async {
    final market = await _readForWrite();
    final scenario = checkoutScenario;
    // Check if this idempotency key already has a saved purchase or receipt.
    final hasSavedAttempt =
        key != null &&
        (market['purchases'][key] != null || market['receipts'][key] != null);
    final result = await _purchase(market, body, key, scenario: scenario);
    await _storage.write(_marketKey, market);
    // Reset one-shot checkout scenario after a fresh purchase attempt completes.
    final shouldResetScenario =
        !hasSavedAttempt && checkoutScenario == scenario;
    if (shouldResetScenario) checkoutScenario = 'normal';
    return result;
  });

  Future<Json> sync(Json body) =>
      _write(() async => _sync(await _readForWrite(), body));

  Future<Json> _write(Future<Json> Function() update) {
    final operation = _writes.then((_) => update());
    _writes = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation;
  }

  Future<Json> _readForWrite() async {
    final stored = await _readMarket();
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

  Future<Json> _productData(String kind, String id) async {
    final key = id.toLowerCase();
    final products = await _products(await _readMarket());
    final product = products.where((item) => item['id'] == key).firstOrNull;
    if (product == null) {
      throw const MockMarketException(404, 'Product not found.');
    }
    final fixture = await _fixture(kind) as Json;
    if (kind == Endpoints.product) {
      return {...product, ...?(fixture[key] as Json?)}..remove('image');
    }
    if (kind == Endpoints.inventory) {
      return {
        ...fixture['default'] as Json,
        ...?(fixture[key] as Json?),
        'productId': key,
        'stock': product['stock'],
      };
    }
    final history = (fixture[key] as List?) ?? [product['originalPrice']];
    return {
      'productId': key,
      'history': [
        ...history,
        if (history.lastOrNull != product['price']) product['price'],
      ],
    };
  }

  Future<Json> _dealsToday(Json market) async {
    final flags = await _fixture(Endpoints.flags) as Json;
    final data = await _fixture(Endpoints.dealsOfDay) as Json;
    final now = DateTime.now().toUtc();
    final date = now.toIso8601String().split('T').first;
    final availability = market['availability'] as Map? ?? const {};
    return {
      'date': date,
      'items': [
        if (flags['showDeals'] == true)
          for (final item in (data['items'] as List).cast<Json>())
            {
              ...item,
              if ((availability[item['productId']] as Map?)?['price']
                  case final int cents)
                'dealPrice': cents / 100,
              'endsAt': '${date}T${(item['endsAt'] as String).split('T').last}',
            },
      ],
    };
  }
}

class const MockMarketException(final int code, final String message)
    implements Exception;
