import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grocer_mate/core/network/connection.dart';
import 'package:grocer_mate/core/network/demo/demo_market_client.dart';
import 'package:grocer_mate/core/network/market_api.dart';
import 'package:grocer_mate/core/storage/local_storage.dart';
import 'package:grocer_mate/features/catalog/data/cached_catalog.dart';
import 'package:grocer_mate/features/catalog/data/catalog_remote_data_source.dart';
import 'package:grocer_mate/features/shopping/data/api_checkout_repository.dart';
import 'package:grocer_mate/features/shopping/data/local_shopping_repository.dart';
import 'package:grocer_mate/features/shopping/domain/entities/shopping.dart';
import 'package:grocer_mate/features/shopping/domain/use_cases/submit_pending_purchase.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const dairy = (category: 'c_dairy', brand: null, search: '', deals: false);
  const milkId = 'p_milk_2pct';
  const breadId = 'p_bread_sourdough';
  const appleId = 'p_apple_gala';
  late _Storage storage;
  late _Connection connection;
  late DemoMarketClient demo;
  late MarketApi api;
  late CatalogRemoteDataSource remote;
  late ApiCheckoutRepository checkout;

  setUp(() {
    storage = _Storage();
    connection = _Connection();
    demo = DemoMarketClient(storage, (path) => File(path).readAsString());
    api = MarketApi(Uri.parse('https://grocer.demo'), demo);
    remote = CatalogRemoteDataSource(api);
    checkout = ApiCheckoutRepository(api, connection);
    addTearDown(api.close);
  });

  test('filters the entire catalog before splitting it into pages', () async {
    final first = await remote.products(dairy, page: 1, pageSize: 2);
    final second = await remote.products(dairy, page: 2, pageSize: 2);
    expect(first.total, 5);
    expect(second.total, first.total);
    expect(first.products.length, 2);
    expect(
      second.products.map((product) => product.id),
      isNot(contains(first.products.first.id)),
    );
    expect(await remote.brands('c_dairy'), [
      'DairyPure',
      'FarmGold',
      'MilkWay',
    ]);

    final result = await api.get(
      'PRODUCTS',
      query: {
        'CATEGORY': 'C_DAIRY',
        'PAGE': '1',
        'PAGESIZE': '10',
        'SEARCH': 'MILK',
        'BRAND': 'dairypure',
      },
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
      final client = MockClient((request) async {
        requests.add(request.url);
        final Object body = switch (request.url.path) {
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
        return http.Response.bytes(utf8.encode(jsonEncode(body)), 200);
      });
      final live = MarketApi(Uri.parse('https://market.example/v1/'), client);
      addTearDown(live.close);
      final source = CatalogRemoteDataSource(live);
      final catalog = CachedCatalog(storage, connection, source);

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

      connection.online = false;
      final restarted = CachedCatalog(storage, connection, source);
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

  test('mixed review and partial fulfillment update stock and keep retries idempotent', () async {
    final lines = [
      CartLine(.fromProduct(await remote.detail(milkId)), 2),
      CartLine(.fromProduct(await remote.detail(appleId)), 1),
      CartLine(.fromProduct(await remote.detail(breadId)), 1),
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
    expect((await remote.inventory(milkId))['stock'], 6);

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
    expect((await remote.checkStock([milkId]))['stocks'], [
      {'productId': milkId, 'stock': 4},
    ]);
    expect((await checkout.order(partial.receipt!.id))['total'], 3.92);

    final localShopping = LocalShoppingRepository(storage);
    final saved = ShoppingData(pending: pending);
    await localShopping.write(saved);
    final submitted = await SubmitPendingPurchase(localShopping, checkout)(
      saved,
    );
    expect(submitted.data.pending, isNull);
    expect(submitted.data.cart.single.product.id, appleId);
    expect(submitted.data.lastOrder?.id, partial.receipt?.id);
  });

  test(
    'suggests, returns fixture history and syncs the same mutation once',
    () async {
      expect(await remote.suggestions('AP'), [
        'apple',
        'apple gala',
        'apple juice',
        'apricot',
      ]);
      expect((await remote.priceHistory(milkId))['history'], [
        1.49,
        1.39,
        1.39,
        1.29,
      ]);
      expect((await remote.dealsOfDay())['items'], hasLength(2));
      expect((await checkout.order('o_7101'))['total'], 6.32);
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
      expect(await checkout.sync(request), {'status': 'ok', 'newVersion': 43});
      expect(await checkout.sync(request), {'status': 'ok', 'newVersion': 43});
      expect((await remote.inventory(milkId))['stock'], 4);
    },
  );
}

class _Connection implements Connection {
  @override
  bool online = true;

  @override
  Stream<bool> get changes => const Stream.empty();
}

class _Storage implements LocalStorage {
  final _values = <String, String>{};

  @override
  Future<JsonObject?> read(String key) async =>
      _values[key] == null ? null : jsonDecode(_values[key]!) as JsonObject;

  @override
  Future<void> write(String key, JsonObject value) async {
    _values[key] = jsonEncode(value);
  }
}
