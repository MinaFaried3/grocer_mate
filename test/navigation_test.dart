import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:grocer_mate/app/grocer_mate_app.dart';
import 'package:grocer_mate/app/mock_market.dart';
import 'package:grocer_mate/core/network/app_connection.dart';
import 'package:grocer_mate/core/network/connectivity_monitor.dart';
import 'package:grocer_mate/core/storage/local_storage.dart';
import 'package:grocer_mate/features/catalog/data/cached_catalog.dart';
import 'package:grocer_mate/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:grocer_mate/features/catalog/presentation/controllers/catalog_bloc.dart';
import 'package:grocer_mate/features/catalog/presentation/controllers/catalog_event.dart';
import 'package:grocer_mate/features/shopping/data/local_shopping_repository.dart';
import 'package:grocer_mate/features/shopping/domain/use_cases/submit_pending_purchase.dart';
import 'package:grocer_mate/features/shopping/presentation/controllers/shopping_bloc.dart';
import 'package:grocer_mate/features/shopping/presentation/controllers/shopping_event.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('opens a product deep link and returns to the Browse tab', (
    tester,
  ) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue =
        '/products/p_milk_2pct';
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );
    final router = await _startApp(tester);

    expect(find.widgetWithText(AppBar, 'Milk 2% (1L)'), findsOneWidget);
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

    await tester.tap(find.text('Milk 2% (1L)'));
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
    await tester.tap(find.byTooltip('Demo settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Price changes'));
    await tester.tap(find.text('Simulate offline'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Queue purchase'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Browse'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Milk 2% (1L)'));
    await tester.pumpAndSettle();
    tester
        .element(find.byType(AppBar))
        .read<AppConnection>()
        .simulateOffline(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/cart');
    expect(find.text('Review order changes'), findsOneWidget);
  });
}

Future<GoRouter> _startApp(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(900, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final seed = await tester.runAsync(
    () => rootBundle.loadString(MockMarket.catalogAsset),
  );
  final connection = AppConnection(_OnlineMonitor());
  await connection.start();
  addTearDown(connection.close);
  final store = _MemoryStorage();
  final market = MockMarket(store, connection, _CatalogBundle(seed!));
  final catalog = CachedCatalog(store, connection, market);
  final shopping = LocalShoppingRepository(store);

  await tester.pumpWidget(
    RepositoryProvider<CatalogRepository>.value(
      value: catalog,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: connection),
          BlocProvider(
            create: (_) => CatalogBloc(catalog)..add(const CatalogRefreshed()),
          ),
          BlocProvider(
            create: (_) => ShoppingBloc(
              shopping,
              SubmitPendingPurchase(shopping, market),
              connection,
              createPurchaseId: () => 'purchase-1',
            )..add(const ShopStarted()),
          ),
        ],
        child: GrocerMateApp(demoSettings: market),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return tester.widget<MaterialApp>(find.byType(MaterialApp)).routerConfig!
      as GoRouter;
}

class _CatalogBundle(final String seed) extends Fake implements AssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) async => seed;
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
