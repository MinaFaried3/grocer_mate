import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grocer_mate/core/network/page_response.dart';
import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:grocer_mate/core/storage/local_storage.dart';
import 'package:grocer_mate/core/storage/market_store.dart';
import 'package:grocer_mate/features/catalog/data/models/product_response.dart';
import 'package:grocer_mate/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:grocer_mate/features/catalog/data/sources/catalog_cache_source.dart';
import 'package:grocer_mate/features/catalog/data/sources/mock_catalog_remote_ds.dart';
import 'package:grocer_mate/features/shopping/data/repositories/shopping_repository_impl.dart';
import 'package:grocer_mate/features/shopping/data/repositories/checkout_repository_impl.dart';
import 'package:grocer_mate/features/shopping/data/sources/local_shopping_source.dart';
import 'package:grocer_mate/features/shopping/data/sources/mock_checkout_remote_ds.dart';
import 'package:grocer_mate/features/shopping/domain/entities/checkout_settings.dart';
import 'package:grocer_mate/features/shopping/domain/entities/shopping.dart';
import 'package:grocer_mate/features/shopping/domain/use_cases/submit_pending_purchase.dart';

void main() {
  const dairy = (category: 'c_dairy', brand: null, search: '', deals: false);
  const milkId = 'p_milk_2pct';
  const breadId = 'p_bread_sourdough';
  const appleId = 'p_apple_gala';
  late _Storage storage;
  late bool online;
  late MockCatalogRemoteDS catalogSource;
  late MockCheckoutRemoteDS checkoutSource;
  late CatalogRepositoryImpl catalog;
  late CheckoutRepositoryImpl checkout;

  setUp(() {
    storage = _Storage();
    online = true;
    final market = MarketStore(storage);
    Future<String> loadMockAsset(String path) => File(path).readAsString();
    catalogSource = MockCatalogRemoteDS(loadMockAsset, market.readAvailability);
    checkoutSource = MockCheckoutRemoteDS(
      loadMockAsset,
      market,
      catalogSource,
      settings: CheckoutSettings(),
    );
    catalog = CatalogRepositoryImpl(
      CatalogCacheSource(storage),
      () => online,
      catalogSource,
    );
    checkout = CheckoutRepositoryImpl(checkoutSource, () => online);
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

    final result = await catalogSource.productsPayload(
      category: 'C_DAIRY',
      page: 1,
      pageSize: 10,
      search: 'MILK',
      brand: 'DairyPure',
    );
    expect(result['total'], 2);
    final response = PageResponse<ProductResponse>.fromJson(
      result,
      (item) => ProductResponse.fromJson(item as Json),
    );
    expect(response.toJson((item) => item.toJson()), result);
    expect((result['data'] as List).map((item) => item['id']), [
      milkId,
      'p_milk_skim',
    ]);
  });

  test(
    'caches catalog list and detail responses for offline browsing',
    () async {
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
        )).products.first.price,
        129,
      );
      expect((await catalog.detail(milkId)).description, isNotEmpty);

      online = false;
      final restarted = CatalogRepositoryImpl(
        CatalogCacheSource(storage),
        () => online,
        catalogSource,
      );
      final cached = await restarted.detail(milkId);
      expect(cached.description, isNotEmpty);
      expect(
        (await restarted.browse(dairy, page: 1, pageSize: 3)).products.first.id,
        milkId,
      );
    },
  );

  test('mixed review and partial fulfillment update stock and keep retries idempotent', () async {
    final lines = [
      CartLine(.fromProduct(await catalog.detail(milkId)), 2),
      CartLine(.fromProduct(await catalog.detail(appleId)), 1),
      CartLine(.fromProduct(await catalog.detail(breadId)), 1),
    ];

    //------------ Verify Price and Stock Review ---------------
    checkoutSource.settings.scenario = 'mixed';
    final result = await checkout.purchase(
      PendingPurchase('mixed', lines),
    ) as PurchaseReview;
    expect(
      result.changes.map(
        (change) => (change.productId, change.currentPrice, change.available),
      ),
      [(milkId, 139, 6), (breadId, 279, 0)],
    );
    expect((await catalogSource.inventory(milkId))['stock'], 6);

    //------------ Retry Partial Fulfillment with the Same Purchase ID ---------------
    final revisedMilk = result.applyTo(lines, {}).first;
    final pending = PendingPurchase('partial', [revisedMilk, lines[1]]);
    checkoutSource.settings.scenario = 'partial';
    final results = await Future.wait([
      checkout.purchase(pending),
      checkout.purchase(pending),
    ]);
    final partial = results.first as PartialPurchase;
    expect((results.last as PartialPurchase).receipt?.id, partial.receipt?.id);
    expect(partial.missing.single.product.id, appleId);
    expect((await catalogSource.checkStock(milkId))['stocks'], [
      {'productId': milkId, 'stock': 4},
    ]);
    expect((await checkoutSource.order(partial.receipt!.id))['total'], 3.92);

    //------------ Replay the Queued Purchase and Restore Missing Items ---------------
    final localShopping = ShoppingRepositoryImpl(LocalShoppingSource(storage));
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
    'suggests, returns mock price history and syncs the same mutation once',
    () async {
      expect((await catalogSource.suggestions('AP'))['suggestions'], [
        'apple',
        'apple gala',
        'apple juice',
        'apricot',
      ]);
      expect((await catalogSource.priceHistory(milkId))['history'], [
        1.49,
        1.39,
        1.39,
        1.29,
      ]);
      expect((await catalogSource.dealsOfDayPayload())['items'], hasLength(2));
      expect((await checkoutSource.order('o_7101'))['total'], 6.32);
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
      expect(await checkoutSource.sync(request), {
        'status': 'ok',
        'newVersion': 43,
      });
      expect(await checkoutSource.sync(request), {
        'status': 'ok',
        'newVersion': 43,
      });
      expect((await catalogSource.inventory(milkId))['stock'], 4);
    },
  );
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
