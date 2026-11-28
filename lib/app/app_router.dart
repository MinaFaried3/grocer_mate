import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/features/catalog/presentation/controllers/catalog_bloc.dart';
import 'package:grocer_mate/features/catalog/presentation/controllers/catalog_event.dart';
import 'package:grocer_mate/features/catalog/presentation/controllers/product_detail_controller.dart';
import 'package:grocer_mate/features/catalog/presentation/ui/screens/catalog_screen.dart';
import 'package:grocer_mate/features/catalog/presentation/ui/screens/product_screen.dart';
import 'package:grocer_mate/features/shopping/presentation/controllers/shopping_bloc.dart';
import 'package:grocer_mate/features/shopping/presentation/controllers/shopping_event.dart';
import 'package:grocer_mate/features/shopping/presentation/ui/screens/shopping_screen.dart';

import 'checkout_settings.dart';
import 'market_home.dart';
import 'settings_sheet.dart';

GoRouter createAppRouter({
  required CheckoutSettings? checkoutSettings,
  required CatalogBloc Function() createCatalogBloc,
  required ProductDetailController Function(String id)
  createProductDetailController,
  required ShoppingBloc Function() createShoppingBloc,
}) {
  final marketNavigatorKey = GlobalKey<NavigatorState>();

  void showSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SettingsSheet(settings: checkoutSettings),
    );
  }

  return .new(
    routes: [
      ShellRoute(
        navigatorKey: marketNavigatorKey,
        builder: (context, state, child) => BlocProvider<ShoppingBloc>(
          create: (_) => createShoppingBloc()..add(const ShopStarted()),
          child: child,
        ),
        routes: [
          StatefulShellRoute.indexedStack(
            builder: (context, state, navigationShell) =>
                MarketHome(navigationShell: navigationShell),
            branches: [
              .new(
                routes: [
                  GoRoute(
                    path: '/',
                    builder: (context, state) => BlocProvider<CatalogBloc>(
                      create: (_) =>
                          createCatalogBloc()..add(const CatalogRefreshed()),
                      child: CatalogScreen(
                        onSettings: () => showSettings(context),
                        onProductSelected: (id) => context.goNamed(
                          'product',
                          pathParameters: {'id': id},
                        ),
                      ),
                    ),
                    routes: [
                      GoRoute(
                        path: 'products/:id',
                        name: 'product',
                        parentNavigatorKey: marketNavigatorKey,
                        builder: (context, state) {
                          final id = state.pathParameters['id']!;
                          return BlocProvider<ProductDetailController>(
                            key: ValueKey(id),
                            create: (_) =>
                                createProductDetailController(id)..load(),
                            child: const ProductScreen(),
                          );
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
      ),
    ],
  );
}
