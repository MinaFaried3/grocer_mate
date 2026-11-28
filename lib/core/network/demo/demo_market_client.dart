import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../storage/json_fields.dart';
import '../../storage/local_storage.dart';
import '../market_api.dart';

part 'demo_checkout.dart';

const demoAssetDirectory = 'assets/mock_api';

class DemoMarketClient extends http.BaseClient {
  DemoMarketClient(
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
  static const _legacyKey = 'mock_market_v1';

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

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bodyBytes = await request.finalize().toBytes();
    final segments = request.url.pathSegments;
    final endpoint = segments.firstOrNull?.toLowerCase() ?? '';
    final id = segments.length == 2 ? segments.last.toLowerCase() : null;
    final query = request.url.queryParameters.map(
      (key, value) => MapEntry(key.toLowerCase(), value.trim()),
    );
    try {
      final Object result;
      if (request.method == 'GET' && segments.length <= 2) {
        result = await _get(endpoint, id, query);
      } else if (request.method == 'POST' &&
          segments.length == 1 &&
          (endpoint == 'purchase' || endpoint == 'sync')) {
        final body = jsonDecode(utf8.decode(bodyBytes));
        if (body is! JsonObject) {
          throw const FormatException('Expected a JSON object.');
        }
        final operation = _writes.then(
          (_) => _post(endpoint, body, request.headers['Idempotency-Key']),
        );
        _writes = operation.then<void>(
          (_) {},
          onError: (Object _, StackTrace _) {},
        );
        result = await operation;
      } else {
        throw const _DemoError(404, 'Endpoint not found.');
      }
      return _response(request, result, 200);
    } on _DemoError catch (error) {
      return _response(request, {'error': error.message}, error.code);
    } on FormatException catch (error) {
      return _response(request, {'error': error.message}, 400);
    }
  }

  http.StreamedResponse _response(
    http.BaseRequest request,
    Object body,
    int status,
  ) => http.StreamedResponse(
    Stream.value(utf8.encode(jsonEncode(body))),
    status,
    request: request,
    headers: {'content-type': 'application/json; charset=utf-8'},
  );

  Future<JsonObject> _readMarket() async =>
      await _storage.read(_marketKey) ?? await _storage.read(_legacyKey) ?? {};

  Future<List<JsonObject>> _products(JsonObject market) async {
    final seed = (await _fixture('products') as List).cast<JsonObject>();
    final availability = market['availability'] as Map? ?? const {};
    return [
      for (final product in seed)
        _withAvailability(
          product,
          availability[product['id']] as Map? ?? const {},
        ),
    ];
  }

  JsonObject _withAvailability(JsonObject product, Map changes) => {
    ...product,
    if (changes['price'] case final int cents) 'price': cents / 100,
    if (changes['stock'] case final int stock) 'stock': stock,
  };

  Future<Object> _get(
    String endpoint,
    String? id,
    Map<String, String> query,
  ) async {
    if (id != null &&
        !const {
          'product',
          'inventory',
          'price-history',
          'orders',
        }.contains(endpoint)) {
      throw const _DemoError(404, 'Endpoint not found.');
    }
    switch (endpoint) {
      case 'categories':
      case 'flags':
        return await _fixture(endpoint) as Object;
      case 'brands':
        final brands = await _fixture('brands') as JsonObject;
        final category = query['categoryid']?.toLowerCase();
        return category == null || category.isEmpty
            ? brands
            : {category: brands[category] ?? <String>[]};
      case 'deals-of-day':
        return _dealsToday(await _readMarket());
      case 'orders':
        final market = await _readMarket();
        final orders = await _fixture('orders') as JsonObject;
        return market['orders']?[id] ??
            orders[id] ??
            (throw const _DemoError(404, 'Order not found.'));
      case 'products':
      case 'product':
      case 'inventory':
      case 'price-history':
      case 'suggest':
      case 'stock-check':
        final products = await _products(await _readMarket());
        return _catalogResponse(endpoint, id, query, products);
      default:
        throw const _DemoError(404, 'Endpoint not found.');
    }
  }

  Future<Object> _catalogResponse(
    String endpoint,
    String? id,
    Map<String, String> query,
    List<JsonObject> products,
  ) async {
    if (endpoint == 'products') {
      final category = query['category']?.toLowerCase() ?? '';
      final brand = query['brand']?.toLowerCase() ?? '';
      final search = query['search']?.toLowerCase() ?? '';
      final words = search.split(RegExp(r'\s+'));
      final matching = products
          .where(
            (product) =>
                (category.isEmpty || product['categoryId'] == category) &&
                (brand.isEmpty ||
                    (product['brand'] as String).toLowerCase() == brand) &&
                words.every(
                  (product['title'] as String).toLowerCase().contains,
                ),
          )
          .toList();
      final page = _positiveQuery(query, 'page', 1);
      final pageSize = _positiveQuery(query, 'pagesize', 10);
      return {
        'data': page - 1 > matching.length ~/ pageSize
            ? <JsonObject>[]
            : matching.skip((page - 1) * pageSize).take(pageSize).toList(),
        'page': page,
        'pageSize': pageSize,
        'total': matching.length,
        'sort': 'popularity_desc',
      };
    }
    if (endpoint == 'suggest') {
      final q = query['q']?.toLowerCase() ?? '';
      final words = await _fixture('suggest') as List;
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
    final byId = {for (final product in products) product['id']: product};
    if (endpoint == 'stock-check') {
      final seed = await _fixture('stock-check') as JsonObject;
      final ids =
          (query['ids']?.split(',') ??
                  (seed['defaultIds'] as List).cast<String>())
              .map((id) => id.trim().toLowerCase())
              .toSet();
      return {
        'stocks': [
          for (final id in ids)
            if (byId[id] case final product?)
              {'productId': id, 'stock': product['stock']},
        ],
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };
    }
    final product =
        byId[id] ?? (throw const _DemoError(404, 'Product not found.'));
    final fixture = await _fixture(endpoint) as JsonObject;
    final history = endpoint == 'price-history'
        ? ((fixture[id] as List?) ?? [product['originalPrice']])
        : const [];
    return switch (endpoint) {
      'product' => {
        ...product,
        ...?(fixture[id] as JsonObject?),
      }..remove('image'),
      'inventory' => {
        ...fixture['default'] as JsonObject,
        ...?(fixture[id] as JsonObject?),
        'productId': id,
        'stock': product['stock'],
      },
      'price-history' => {
        'productId': id,
        'history': [
          ...history,
          if (history.lastOrNull != product['price']) product['price'],
        ],
      },
      _ => throw const _DemoError(404, 'Endpoint not found.'),
    };
  }

  int _positiveQuery(Map<String, String> query, String key, int fallback) {
    final raw = query[key];
    if (raw == null) return fallback;
    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 1) throw FormatException('Invalid $key.');
    return parsed;
  }

  Future<JsonObject> _dealsToday(JsonObject market) async {
    final flags = await _fixture('flags') as JsonObject;
    final data = await _fixture('deals-of-day') as JsonObject;
    final now = DateTime.now().toUtc();
    final date = now.toIso8601String().split('T').first;
    final availability = market['availability'] as Map? ?? const {};
    return {
      'date': date,
      'items': [
        if (flags['showDeals'] == true)
          for (final item in (data['items'] as List).cast<JsonObject>())
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

class const _DemoError(final int code, final String message)
    implements Exception;
