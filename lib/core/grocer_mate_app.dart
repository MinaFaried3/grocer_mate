import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/routing/app_router.dart';
import 'package:grocer_mate/core/settings/checkout_settings.dart';
import 'package:grocer_mate/core/theme/market_theme.dart';
import 'package:grocer_mate/features/app/presentation/ui/widgets/offline_banner.dart';
import 'package:grocer_mate/features/catalog/presentation/controllers/catalog_bloc.dart';
import 'package:grocer_mate/features/catalog/presentation/controllers/product_detail_controller.dart';
import 'package:grocer_mate/features/shopping/presentation/controllers/shopping_bloc.dart';

class const GrocerMateApp({
  super.key,
  required final CheckoutSettings? Function() getCheckoutSettings,
  required final CatalogBloc Function() createCatalogBloc,
  required final ProductDetailController Function(String id)
  createProductDetailController,
  required final ShoppingBloc Function() createShoppingBloc,
}) extends StatefulWidget {
  @override
  State<GrocerMateApp> createState() => _GrocerMateAppState();
}

class _GrocerMateAppState() extends State<GrocerMateApp> {
  late final GoRouter _router = createAppRouter(
    getCheckoutSettings: widget.getCheckoutSettings,
    createCatalogBloc: widget.createCatalogBloc,
    createProductDetailController: widget.createProductDetailController,
    createShoppingBloc: widget.createShoppingBloc,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    routerConfig: _router,
    debugShowCheckedModeBanner: false,
    title: 'GrocerMate',
    theme: MarketThemeFactory.light.build(),
    darkTheme: MarketThemeFactory.dark.build(),
    builder: (context, child) => Column(
      children: [
        const OfflineBanner(),
        Expanded(child: child!),
      ],
    ),
  );
}
