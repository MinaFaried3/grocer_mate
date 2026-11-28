import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grocer_mate/core/mock/mock_market.dart';
import 'package:grocer_mate/core/network/dio_factory.dart';
import 'package:grocer_mate/core/network/dio_market_api.dart';
import 'package:grocer_mate/core/network/market_api.dart';
import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:grocer_mate/core/storage/local_storage.dart';
import 'package:grocer_mate/features/catalog/data/cached_catalog.dart';
import 'package:grocer_mate/features/catalog/data/catalog_remote_data_source.dart';
import 'package:grocer_mate/features/catalog/data/mock_catalog_repository.dart';
import 'package:grocer_mate/features/shopping/data/api_checkout_repository.dart';
import 'package:grocer_mate/features/shopping/data/local_shopping_repository.dart';
import 'package:grocer_mate/features/shopping/data/mock_checkout_repository.dart';
import 'package:grocer_mate/features/shopping/domain/entities/shopping.dart';
import 'package:grocer_mate/features/shopping/domain/use_cases/submit_pending_purchase.dart';

import 'fixtures.dart';

void main() {
  const dairy = (category: 'c_dairy', brand: null, search: '', deals: false);
  const milkId = 'p_milk_2pct';
  const breadId = 'p_bread_sourdough';
  const appleId = 'p_apple_gala';
  late _Storage storage;
  late bool online;
  late MockMarket demo;
  late MockCatalogRepository catalog;
  late MockCheckoutRepository checkout;

  setUp(() {
    storage = _Storage();
    online = true;
    demo = MockMarket(storage, (path) => File(path).readAsString());
    catalog = MockCatalogRepository(storage, () => online, demo);
    checkout = MockCheckoutRepository(demo, () => online);
  });

  test('filters the entire catalog before splitting it into pages', () async {
    final first = await catalog.browse(dairy, page: 1, pageSize: 2);
    final second = await catalog.browse(dairy, page: 2, pageSize: 2);
    expect(first.total, 5);
    expect(second.total, first.total);
    expect(first.products.length, 2);
    expect(
      second.products.map((product) => product.id),
      isNot(contains(first.products.first.id)),
    );
    expect(first.brands, ['DairyPure', 'FarmGold', 'MilkWay']);

    final result = await demo.products(
      category: 'C_DAIRY',
      page: 1,
      pageSize: 10,
      search: 'MILK',
      brand: 'DairyPure',
    );
    expect(result['total'], 2);
    expect((result['data'] as List).map((item) => item['id']), [
      milkId,
      'p_milk_skim',
    ]);
  });

  test(
    'caches remote list and detail responses using their wire formats',
    () async {
      final requests = <Uri>[];
      final server = await _serve((request) async {
        requests.add(request.uri);
        final Object body = switch (request.uri.path) {
          '/v1/categories' => [
            {'id': 'c_dairy', 'name': 'Dairy', 'icon': '🥛'},
          ],
          '/v1/brands' => {
            'c_dairy': ['DairyPure'],
          },
          '/v1/products' => {
            'data': [
              {
                'id': milkId,
                'title': 'Milk',
                'brand': 'DairyPure',
                'price': 1,
                'originalPrice': 1.49,
                'stock': 6,
                'image': 'https://example.com/milk.webp',
                'categoryId': 'c_dairy',
                'rating': 4.3,
                'badges': ['deal'],
              },
            ],
            'total': 1,
          },
          '/v1/product/$milkId' => {
            'id': milkId,
            'title': 'Milk',
            'brand': 'DairyPure',
            'price': 1,
            'originalPrice': 1.49,
            'stock': 6,
            'images': ['https://example.com/milk.webp'],
            'description': 'Pasteurized cow milk.',
          },
          _ => throw StateError('Unexpected endpoint'),
        };
        request.response.write(jsonEncode(body));
      });
      final live = DioMarketApi(createDio(server.resolve('/v1').toString()));
      addTearDown(live.close);
      final source = CatalogRemoteDataSource(live);
      final catalog = CachedCatalog(storage, () => online, source);

      final query = (
        category: 'c_dairy',
        brand: 'DairyPure',
        search: 'milk',
        deals: false,
      );
      expect(
        (await catalog.browse(
          query,
          page: 1,
          pageSize: 3,
        )).products.single.price,
        100,
      );
      expect(
        (await catalog.detail(milkId)).description,
        'Pasteurized cow milk.',
      );
      expect(
        requests
            .singleWhere((uri) => uri.path.endsWith('/products'))
            .queryParameters,
        {
          'page': '1',
          'pageSize': '3',
          'category': 'c_dairy',
          'brand': 'DairyPure',
          'search': 'milk',
        },
      );

      online = false;
      final restarted = CachedCatalog(storage, () => online, source);
      final cached = await restarted.detail(milkId);
      expect(cached.description, 'Pasteurized cow milk.');
      expect(cached.rating, 4.3);
      expect(
        (await restarted.browse(
          dairy,
          page: 1,
          pageSize: 3,
        )).products.single.id,
        milkId,
      );
      expect(requests, hasLength(4));
    },
  );

  test('sends the checkout key and reads review responses from Dio', () async {
    final server = await _serve((request) async {
      if (request.uri.path == '/flags') {
        request.response.write(jsonEncode({'currency': 'USD'}));
        return;
      }
      if (request.uri.path == '/purchase') {
        expect(request.method, 'POST');
        expect(request.headers.value('Idempotency-Key'), 'pending-1');
        expect(
          jsonDecode(await utf8.decoder.bind(request).join())['currency'],
          'USD',
        );
        request.response
          ..statusCode = HttpStatus.conflict
          ..write(
            jsonEncode({
              'status': 'out_of_stock',
              'items': [
                {'productId': milk.id, 'available': 0},
              ],
            }),
          );
        return;
      }
      request.response.statusCode = HttpStatus.notFound;
    });
    final api = DioMarketApi(createDio(server.toString()));
    addTearDown(api.close);
    final liveCheckout = ApiCheckoutRepository(api, () => true);
    final review = await liveCheckout.purchase(
      PendingPurchase('pending-1', [CartLine(.fromProduct(milk), 1)]),
    ) as PurchaseReview;
    expect(review.changes.single.available, 0);
    await expectLater(
      api.get<Object>('missing'),
      throwsA(
        isA<ApiException>().having((error) => error.statusCode, 'status', 404),
      ),
    );
  });

  test('mixed review and partial fulfillment update stock and keep retries idempotent', () async {
    final lines = [
      CartLine(.fromProduct(await catalog.detail(milkId)), 2),
      CartLine(.fromProduct(await catalog.detail(appleId)), 1),
      CartLine(.fromProduct(await catalog.detail(breadId)), 1),
    ];
    demo.checkoutScenario = 'mixed';
    final result = await checkout.purchase(
      PendingPurchase('mixed', lines),
    ) as PurchaseReview;
    expect(
      result.changes.map(
        (change) => (change.productId, change.currentPrice, change.available),
      ),
      [(milkId, 139, 6), (breadId, 279, 0)],
    );
    expect((await demo.inventory(milkId))['stock'], 6);

    final revisedMilk = result.applyTo(lines, {}).first;
    final pending = PendingPurchase('partial', [revisedMilk, lines[1]]);
    demo.checkoutScenario = 'partial';
    final results = await Future.wait([
      checkout.purchase(pending),
      checkout.purchase(pending),
    ]);
    final partial = results.first as PartialPurchase;
    expect((results.last as PartialPurchase).receipt?.id, partial.receipt?.id);
    expect(partial.missing.single.product.id, appleId);
    expect((await demo.checkStock(milkId))['stocks'], [
      {'productId': milkId, 'stock': 4},
    ]);
    expect((await demo.order(partial.receipt!.id))['total'], 3.92);

    final localShopping = LocalShoppingRepository(storage);
    final saved = ShoppingData(pending: pending);
    await localShopping.write(saved);
    final submitted = await SubmitPendingPurchase(
      localShopping,
      checkout.purchase,
    )(saved);
    expect(submitted.data.pending, isNull);
    expect(submitted.data.cart.single.product.id, appleId);
    expect(submitted.data.lastOrder?.id, partial.receipt?.id);
  });

  test(
    'suggests, returns fixture history and syncs the same mutation once',
    () async {
      expect((await demo.suggestions('AP'))['suggestions'], [
        'apple',
        'apple gala',
        'apple juice',
        'apricot',
      ]);
      expect((await demo.priceHistory(milkId))['history'], [
        1.49,
        1.39,
        1.39,
        1.29,
      ]);
      expect((await demo.dealsOfDay())['items'], hasLength(2));
      expect((await demo.order('o_7101'))['total'], 6.32);
      final request = {
        'baseVersion': 42,
        'mutations': [
          {
            'op': 'purchase',
            'idempotencyKey': 'uuid123',
            'payload': {
              'items': [
                {'productId': milkId, 'qty': 2},
              ],
            },
          },
        ],
      };
      expect(await demo.sync(request), {'status': 'ok', 'newVersion': 43});
      expect(await demo.sync(request), {'status': 'ok', 'newVersion': 43});
      expect((await demo.inventory(milkId))['stock'], 4);
    },
  );
}

Future<Uri> _serve(Future<void> Function(HttpRequest) handle) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  addTearDown(() => server.close(force: true));
  server.listen((request) async {
    try {
      await handle(request);
    } finally {
      await request.response.close();
    }
  });
  return Uri.parse('http://127.0.0.1:${server.port}');
}

class _Storage implements LocalStorage {
  final _values = <String, String>{};

  @override
  Future<Json?> read(String key) async =>
      _values[key] == null ? null : jsonDecode(_values[key]!) as Json;

  @override
  Future<void> write(String key, Json value) async {
    _values[key] = jsonEncode(value);
  }
}
