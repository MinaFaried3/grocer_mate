import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:grocer_mate/core/mock/mock_market.dart';
import 'package:grocer_mate/core/storage/hive_local_storage.dart';
import 'package:grocer_mate/features/catalog/data/mock_catalog_repository.dart';
import 'package:grocer_mate/features/shopping/data/local_shopping_repository.dart';
import 'package:grocer_mate/features/shopping/domain/entities/shopping.dart';

import 'fixtures.dart';

void main() {
  late Directory directory;
  late HiveLocalStorage storage;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('grocer-mate-hive-');
    storage = HiveLocalStorage(directory: directory.path);
  });

  tearDown(() async {
    await storage.close();
    await directory.delete(recursive: true);
  });

  test(
    'persists the cart, saved items, and pending purchase across reopen',
    () async {
      final milkLine = CartLine(CartProduct.fromProduct(milk), 2);
      final breadLine = CartLine(CartProduct.fromProduct(bread), 1);
      final data = ShoppingData(
        cart: [breadLine],
        saved: [milkLine],
        pending: PendingPurchase('queued-purchase', [
          milkLine,
        ], attempted: true),
      );
      final shopping = LocalShoppingRepository(storage);
      expect((await shopping.read()).cart, isEmpty);
      await shopping.write(data);
      await storage.close();

      storage = HiveLocalStorage(directory: directory.path);
      final restarted = LocalShoppingRepository(storage);
      expect((await restarted.read()).toJson(), data.toJson());
    },
  );

  test(
    'opens the Hive catalog cache offline after reopening the box',
    () async {
      const query = (
        category: 'c_dairy',
        brand: null,
        search: '',
        deals: false,
      );
      const productId = 'p_milk_2pct';
      Future<String> loadAsset(String path) => File(path).readAsString();

      final online = MockCatalogRepository(
        storage,
        () => true,
        MockMarket(storage, loadAsset),
      );
      final page = await online.browse(query, page: 1, pageSize: 3);
      final detail = await online.detail(productId);
      await storage.close();

      storage = HiveLocalStorage(directory: directory.path);
      final offline = MockCatalogRepository(
        storage,
        () => false,
        MockMarket(storage, loadAsset),
      );
      final cached = await offline.browse(query, page: 1, pageSize: 3);
      expect(
        cached.products.map((product) => product.id),
        page.products.map((product) => product.id),
      );
      expect((await offline.detail(productId)).description, detail.description);
    },
  );

  test('reads the existing catalog cache format with deals offline', () async {
    const dealPrice = 99;
    const description = 'Cached product details';
    const query = (category: 'dairy', brand: null, search: '', deals: true);
    final endsAt = DateTime.now().toUtc().add(const Duration(days: 1));

    await storage.write('catalog_v2', {
      'categories': [
        {'id': 'dairy', 'name': 'Dairy', 'icon': 'milk'},
      ],
      'brands': {
        'dairy': [milk.brand],
      },
      'products': [milk.toJson()],
      'details': [
        {...milk.toJson(), 'description': description},
      ],
      'deals': [
        {'id': milk.id, 'price': dealPrice, 'endsAt': endsAt.toIso8601String()},
      ],
    });
    final offline = MockCatalogRepository(
      storage,
      () => false,
      MockMarket(storage, (path) => File(path).readAsString()),
    );

    final page = await offline.browse(query, page: 1, pageSize: 3);
    expect(page.categories.single.name, 'Dairy');
    expect(page.brands, [milk.brand]);
    expect(page.products.single.price, dealPrice);

    final detail = await offline.detail(milk.id);
    expect(detail.price, dealPrice);
    expect(detail.description, description);
  });
}
