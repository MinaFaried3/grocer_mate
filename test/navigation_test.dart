import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:grocer_mate/core/grocer_mate_app.dart';
import 'package:grocer_mate/core/injection/get_it_injector.dart';
import 'package:grocer_mate/core/network/connectivity/connection_checker.dart';
import 'package:grocer_mate/core/mock/mock_market.dart';
import 'package:grocer_mate/core/settings/checkout_settings.dart';
import 'package:grocer_mate/core/storage/local_storage.dart';
import 'package:grocer_mate/features/app/presentation/controllers/app_connection_cubit.dart';
import 'package:grocer_mate/features/catalog/data/repositories/mock_catalog_repository.dart';
import 'package:grocer_mate/features/catalog/data/sources/catalog_cache_source.dart';
import 'package:grocer_mate/features/catalog/data/sources/mock_catalog_source.dart';
import 'package:grocer_mate/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:grocer_mate/features/catalog/presentation/controllers/catalog_bloc.dart';
import 'package:grocer_mate/features/catalog/presentation/controllers/product_detail_controller.dart';
import 'package:grocer_mate/features/shopping/data/repositories/local_shopping_repository.dart';
import 'package:grocer_mate/features/shopping/data/repositories/mock_checkout_repository.dart';
import 'package:grocer_mate/features/shopping/data/sources/local_shopping_source.dart';
import 'package:grocer_mate/features/shopping/data/sources/mock_checkout_source.dart';
import 'package:grocer_mate/features/shopping/domain/entities/shopping.dart';
import 'package:grocer_mate/features/shopping/domain/repositories/checkout_repository.dart';
import 'package:grocer_mate/features/shopping/domain/repositories/shopping_repository.dart';
import 'package:grocer_mate/features/shopping/domain/use_cases/submit_pending_purchase.dart';
import 'package:grocer_mate/features/shopping/presentation/controllers/shopping_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'uses saved inventory and receipts when processing a purchase',
    () async {
      final connection = AppConnectionCubit(_OnlineChecker());
      addTearDown(connection.close);
      final store = _MemoryStorage();
      await store.write('local_market_v1', {
        'availability': {
          'milk': {'price': 129, 'stock': 3},
        },
        'receipts': {
          'previous': {'id': 'GM-1001', 'total': 235},
        },
      });
      final demo = MockMarket(
        store,
        (path) => path.endsWith('/products.json')
            ? Future.value(
                '[{"id":"milk","title":"Milk","price":1.29,"stock":6}]',
              )
            : rootBundle.loadString(path),
      );
      final checkout = MockCheckoutRepository(
        MockCheckoutSource(demo),
        () => connection.online,
      );
      final catalog = await demo.products();
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

  testWidgets('opens a product route and returns to the Browse tab', (
    tester,
  ) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue =
        '/products/p_milk_2pct';
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );
    var catalogCreations = 0;
    final router = await _startApp(
      tester,
      onCreateCatalog: () => catalogCreations++,
    );

    expect(find.widgetWithText(AppBar, 'Milk 2% 1L'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(catalogCreations, 1);

    router.go('/products/p_bread_sourdough');
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Sourdough Bread'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(catalogCreations, 1);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });

  testWidgets('defers product and settings factories until their views build', (
    tester,
  ) async {
    var productCreations = 0;
    await _startApp(tester, onCreateProduct: () => productCreations++);
    final injector = GetItInjector();
    expect(productCreations, 0);
    expect(injector.isRegistered<CheckoutSettings>(), isFalse);

    await tester.tap(find.byTooltip('Settings'));
    expect(injector.isRegistered<CheckoutSettings>(), isFalse);
    await tester.pumpAndSettle();
    expect(injector.isRegistered<CheckoutSettings>(), isTrue);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Milk 2% 1L'));
    expect(productCreations, 0);
    await tester.pumpAndSettle();
    expect(productCreations, 1);
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
        .read<AppConnectionCubit>()
        .setOfflineMode(false);
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Milk 2% 1L'), findsOneWidget);
  });

  testWidgets('shows and clears the offline banner as connectivity changes', (
    tester,
  ) async {
    final connectionChanges = StreamController<bool>()..add(true);
    addTearDown(connectionChanges.close);
    await _startApp(tester, connectionChanges: connectionChanges.stream);

    final banner = find.text('Offline mode · browsing the cached catalog');
    expect(banner, findsNothing);
    for (final connected in [false, true, false, true]) {
      connectionChanges.add(connected);
      await tester.pumpAndSettle();
      expect(banner, connected ? findsNothing : findsOneWidget);
    }
  });

  testWidgets('preserves Browse search and opens checkout review over Cart', (
    tester,
  ) async {
    final router = await _startApp(tester);
    final search = find.byKey(const ValueKey('catalog-search'));
    await tester.enterText(search, 'milk');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    //------------ Keep Browse Search Across Tabs ---------------
    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/saved');
    await tester.tap(find.text('Browse groceries'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(search).controller!.text, 'milk');

    //------------ Open Product Details and Add to Cart ---------------
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

    //------------ Enable Offline Mode and Queue Checkout ---------------
    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Price changes'));
    await tester.tap(find.text('Offline mode'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(
      find.text('Offline mode · browsing the cached catalog'),
      findsOneWidget,
    );
    await tester.tap(find.text('Queue purchase'));
    await tester.pumpAndSettle();

    //------------ Reconnect and Show Review Over Cart ---------------
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Milk 2% 1L'));
    await tester.pumpAndSettle();
    tester
        .element(find.byType(AppBar))
        .read<AppConnectionCubit>()
        .setOfflineMode(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/cart');
    expect(find.text('Review order changes'), findsOneWidget);
  });
}

Future<GoRouter> _startApp(
  WidgetTester tester, {
  bool offline = false,
  Stream<bool>? connectionChanges,
  VoidCallback? onCreateCatalog,
  VoidCallback? onCreateProduct,
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  //------------ Load Bundled Market Fixtures ---------------
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

  //------------ Create Repositories and Connection State ---------------
  final connection = AppConnectionCubit(_OnlineChecker(connectionChanges));
  connection.setOfflineMode(offline);
  addTearDown(connection.close);
  final store = _MemoryStorage();
  final demo = MockMarket(store, (path) async => fixtures![path]!);
  final catalog = MockCatalogRepository(
    CatalogCacheSource(store),
    () => connection.online,
    MockCatalogSource(demo),
  );
  final checkout = MockCheckoutRepository(
    MockCheckoutSource(demo),
    () => connection.online,
  );
  final shopping = LocalShoppingRepository(LocalShoppingSource(store));

  //------------ Register the Test Dependencies ---------------
  final injector = GetItInjector();
  await injector.reset();
  addTearDown(injector.reset);
  var tracking = false;
  injector
    ..singleton<AppConnectionCubit>(() => connection)
    ..singleton<LocalStorage>(() => store)
    ..singleton<MockMarket>(() => demo)
    ..singleton<CatalogRepository>(() => catalog)
    ..singleton<CheckoutRepository>(() => checkout)
    ..singleton<ShoppingRepository>(() => shopping)
    ..factory<CatalogBloc>(() {
      if (tracking) onCreateCatalog?.call();
      return CatalogBloc(catalog);
    })
    ..factoryWithParameter<ProductDetailController, String>((id) {
      if (tracking) onCreateProduct?.call();
      return ProductDetailController(catalog, id);
    }, 'seed')
    ..factory<ShoppingBloc>(
      () => ShoppingBloc(
        shopping,
        SubmitPendingPurchase(shopping, checkout.purchase),
        () => connection.online,
        connectionChanges: connection.changes,
        createPurchaseId: () => 'purchase-1',
      ),
    );
  tracking = true;

  //------------ Launch the App and Read Its Router ---------------
  await tester.pumpWidget(const GrocerMateApp());
  await tester.pumpAndSettle();
  return tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
      as GoRouter;
}

class _OnlineChecker([final Stream<bool>? _status])
    implements ConnectionChecker {
  @override
  Future<bool> get isConnected async => true;

  @override
  Stream<bool> get status => _status ?? Stream.value(true);
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
