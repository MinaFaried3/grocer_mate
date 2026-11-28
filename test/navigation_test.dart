import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:grocer_mate/app/grocer_mate_app.dart';
import 'package:grocer_mate/app/checkout_settings.dart';
import 'package:grocer_mate/core/network/demo/demo_market_client.dart';
import 'package:grocer_mate/core/network/market_api.dart';
import 'package:grocer_mate/core/network/app_connection.dart';
import 'package:grocer_mate/core/network/connectivity_monitor.dart';
import 'package:grocer_mate/core/storage/local_storage.dart';
import 'package:grocer_mate/features/catalog/data/cached_catalog.dart';
import 'package:grocer_mate/features/catalog/data/catalog_remote_data_source.dart';
import 'package:grocer_mate/features/catalog/presentation/controllers/catalog_bloc.dart';
import 'package:grocer_mate/features/catalog/presentation/controllers/product_detail_controller.dart';
import 'package:grocer_mate/features/shopping/data/api_checkout_repository.dart';
import 'package:grocer_mate/features/shopping/data/local_shopping_repository.dart';
import 'package:grocer_mate/features/shopping/domain/entities/shopping.dart';
import 'package:grocer_mate/features/shopping/domain/use_cases/submit_pending_purchase.dart';
import 'package:grocer_mate/features/shopping/presentation/controllers/shopping_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'preserves local inventory and receipts across the storage rename',
    () async {
      final connection = AppConnection(_OnlineMonitor());
      addTearDown(connection.close);
      final store = _MemoryStorage();
      await store.write('mock_market_v1', {
        'availability': {
          'milk': {'price': 129, 'stock': 3},
        },
        'receipts': {
          'previous': {'id': 'GM-1001', 'total': 235},
        },
      });
      final demo = DemoMarketClient(
        store,
        (path) => path.endsWith('/products.json')
            ? Future.value(
                '[{"id":"milk","title":"Milk","price":1.29,"stock":6}]',
              )
            : rootBundle.loadString(path),
      );
      final api = MarketApi(Uri.parse('https://grocer.demo'), demo);
      final checkout = ApiCheckoutRepository(api, connection);
      final catalog = await api.get('products');
      expect((catalog['data'] as List).single['stock'], 3);

      final next = PendingPurchase('next', [CartLine(.fromProduct(milk), 1)]);
      final receipt = await checkout.purchase(next) as OrderReceipt;
      expect(receipt.id, 'o_7103');
      final stored = await store.read('local_market_v1');
      expect(stored?['availability']['milk']['stock'], 2);

      final previous = await checkout.purchase(
        PendingPurchase('previous', next.lines),
      ) as OrderReceipt;
      expect(previous.id, 'GM-1001');
      expect(previous.total, 235);
    },
  );

  testWidgets('opens a product deep link and returns to the Browse tab', (
    tester,
  ) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue =
        '/products/p_milk_2pct';
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );
    final router = await _startApp(tester);

    expect(find.widgetWithText(AppBar, 'Milk 2% 1L'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    router.go('/products/p_bread_sourdough');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Sourdough Bread'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });

  testWidgets('retries product details after reconnecting', (tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue =
        '/products/p_milk_2pct';
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );
    await _startApp(tester, offline: true);

    expect(find.text('Connect to download product details.'), findsOneWidget);
    tester
        .element(find.byType(AppBar))
        .read<AppConnection>()
        .setOfflineMode(false);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Milk 2% 1L'), findsOneWidget);
  });

  testWidgets('preserves Browse search and opens checkout review over Cart', (
    tester,
  ) async {
    final router = await _startApp(tester);
    final search = find.byKey(const ValueKey('catalog-search'));
    await tester.enterText(search, 'milk');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/saved');
    await tester.tap(find.text('Browse groceries'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(search).controller!.text, 'milk');

    await tester.tap(find.text('Milk 2% 1L'));
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      '/products/p_milk_2pct',
    );
    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Price changes'));
    await tester.tap(find.text('Offline mode'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Queue purchase'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Milk 2% 1L'));
    await tester.pumpAndSettle();
    tester
        .element(find.byType(AppBar))
        .read<AppConnection>()
        .setOfflineMode(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/cart');
    expect(find.text('Review order changes'), findsOneWidget);
  });
}

Future<GoRouter> _startApp(WidgetTester tester, {bool offline = false}) async {
  await tester.binding.setSurfaceSize(const Size(900, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final fixtures = await tester.runAsync(
    () async => {
      for (final name in [
        'categories',
        'brands',
        'products',
        'product',
        'flags',
        'purchase',
        'deals-of-day',
        'inventory',
      ])
        '$demoAssetDirectory/$name.json': await rootBundle.loadString(
          '$demoAssetDirectory/$name.json',
        ),
    },
  );
  final connection = AppConnection(_OnlineMonitor());
  await connection.start();
  connection.setOfflineMode(offline);
  addTearDown(connection.close);
  final store = _MemoryStorage();
  final demo = DemoMarketClient(store, (path) async => fixtures![path]!);
  final api = MarketApi(Uri.parse('https://grocer.demo'), demo);
  final catalog = CachedCatalog(
    store,
    connection,
    CatalogRemoteDataSource(api),
  );
  final checkout = ApiCheckoutRepository(api, connection);
  final shopping = LocalShoppingRepository(store);

  await tester.pumpWidget(
    BlocProvider<AppConnection>.value(
      value: connection,
      child: GrocerMateApp(
        checkoutSettings: CheckoutSettings(demo),
        createCatalogBloc: () => CatalogBloc(catalog),
        createProductDetailController: (id) =>
            ProductDetailController(catalog, id),
        createShoppingBloc: () => ShoppingBloc(
          shopping,
          SubmitPendingPurchase(shopping, checkout),
          connection,
          createPurchaseId: () => 'purchase-1',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
      as GoRouter;
}

class _OnlineMonitor implements ConnectivityMonitor {
  @override
  Future<bool> checkOnline() async => true;

  @override
  Stream<bool> get changes => const Stream.empty();
}

class _MemoryStorage implements LocalStorage {
  final _values = <String, Map<String, dynamic>>{};

  @override
  Future<Map<String, dynamic>?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, Map<String, Object?> value) async {
    _values[key] = value;
  }
}
