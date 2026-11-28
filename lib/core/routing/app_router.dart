import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/injection/dependencies.dart';
import 'package:grocer_mate/core/settings/settings_dependencies.dart';
import 'package:grocer_mate/core/settings/settings_sheet.dart';
import 'package:grocer_mate/features/catalog/injection/catalog_dependencies.dart';
import 'package:grocer_mate/features/catalog/presentation/controllers/catalog_bloc.dart';
import 'package:grocer_mate/features/catalog/presentation/controllers/catalog_event.dart';
import 'package:grocer_mate/features/catalog/presentation/controllers/product_detail_controller.dart';
import 'package:grocer_mate/features/catalog/presentation/ui/screens/catalog_screen.dart';
import 'package:grocer_mate/features/catalog/presentation/ui/screens/product_screen.dart';
import 'package:grocer_mate/features/shopping/injection/shopping_dependencies.dart';
import 'package:grocer_mate/features/shopping/presentation/controllers/shopping_bloc.dart';
import 'package:grocer_mate/features/shopping/presentation/controllers/shopping_event.dart';
import 'package:grocer_mate/features/shopping/presentation/ui/screens/cart_screen.dart';
import 'package:grocer_mate/features/shopping/presentation/ui/screens/saved_screen.dart';

import 'market_home.dart';
import 'routes_constants.dart';

GoRouter createAppRouter() {
  void showSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => SettingsSheet(settings: injector.getCheckoutSettings()),
    );
  }

  return .new(
    navigatorKey: RoutesConstants.rootNavigatorKey,
    routes: [
      //------------ Market Shell Route ---------------
      ShellRoute(
        navigatorKey: RoutesConstants.marketNavigatorKey,
        builder: (context, state, child) => MultiBlocProvider(
          providers: [
            //------------ Shopping Bloc Provider ---------------
            BlocProvider<ShoppingBloc>(
              create: (_) =>
                  injector.createShoppingBloc()..add(const ShopStarted()),
            ),

            //------------ Catalog Bloc Provider ---------------
            BlocProvider<CatalogBloc>(
              lazy: true,
              create: (_) =>
                  injector.createCatalogBloc()..add(const CatalogRefreshed()),
            ),
          ],
          child: child,
        ),
        routes: [
          //------------ Navigation Bar Shell Route ---------------
          ShellRoute(
            navigatorKey: RoutesConstants.shellNavigatorKey,
            builder: (context, state, child) =>
                MarketHome(location: state.uri.path, child: child),
            routes: [
              //------------ Browse Route ---------------
              GoRoute(
                path: RoutesConstants.browse,
                builder: (context, state) => CatalogScreen(
                  isVisible: state.uri.path == RoutesConstants.browse,
                  onSettings: () => showSettings(context),
                  onProductSelected: (id) => context.goNamed(
                    RoutesConstants.productName,
                    pathParameters: {'id': id},
                  ),
                ),
                routes: [
                  //------------ Product Route ---------------
                  GoRoute(
                    path: RoutesConstants.product,
                    name: RoutesConstants.productName,
                    parentNavigatorKey: RoutesConstants.marketNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return BlocProvider<ProductDetailController>(
                        key: ValueKey(id),
                        create: (_) =>
                            injector.createProductDetailController(id)..load(),
                        child: const ProductScreen(),
                      );
                    },
                  ),
                ],
              ),

              //------------ Cart Route ---------------
              GoRoute(
                path: RoutesConstants.cart,
                builder: (context, state) => CartScreen(
                  onBrowse: () => context.go(RoutesConstants.browse),
                  onSettings: () => showSettings(context),
                ),
              ),

              //------------ Saved Route ---------------
              GoRoute(
                path: RoutesConstants.saved,
                builder: (context, state) => SavedScreen(
                  onBrowse: () => context.go(RoutesConstants.browse),
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
