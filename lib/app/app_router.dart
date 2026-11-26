import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/features/catalog/presentation/ui/screens/catalog_screen.dart';
import 'package:grocer_mate/features/catalog/presentation/ui/screens/product_screen.dart';
import 'package:grocer_mate/features/shopping/presentation/ui/screens/shopping_screen.dart';

import 'demo_settings_sheet.dart';
import 'market_home.dart';
import 'mock_market.dart';

GoRouter createAppRouter(MockMarket market) {
  final rootNavigatorKey = GlobalKey<NavigatorState>();

  void showSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DemoSettingsSheet(market: market),
    );
  }

  return .new(
    navigatorKey: rootNavigatorKey,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MarketHome(navigationShell: navigationShell),
        branches: [
          .new(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => CatalogScreen(
                  onSettings: () => showSettings(context),
                  onProductSelected: (id) =>
                      context.goNamed('product', pathParameters: {'id': id}),
                ),
                routes: [
                  GoRoute(
                    path: 'products/:id',
                    name: 'product',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return ProductScreen(key: ValueKey(id), id: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          .new(
            routes: [
              GoRoute(
                path: '/cart',
                builder: (context, state) => ShoppingScreen(
                  saved: false,
                  onBrowse: () => context.go('/'),
                  onSettings: () => showSettings(context),
                ),
              ),
            ],
          ),
          .new(
            routes: [
              GoRoute(
                path: '/saved',
                builder: (context, state) => ShoppingScreen(
                  saved: true,
                  onBrowse: () => context.go('/'),
                  onSettings: () => showSettings(context),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
