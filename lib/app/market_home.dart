import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/network/app_connection.dart';
import 'package:grocer_mate/features/catalog/presentation/catalog_bloc.dart';
import 'package:grocer_mate/features/catalog/presentation/catalog_screen.dart';
import 'package:grocer_mate/features/shopping/presentation/checkout_sheet.dart';
import 'package:grocer_mate/features/shopping/presentation/shopping_bloc.dart';
import 'package:grocer_mate/features/shopping/presentation/shopping_screen.dart';

import 'demo_settings_sheet.dart';
import 'mock_market.dart';

class const MarketHome({super.key, required final MockMarket market})
    extends StatefulWidget {
  @override
  State<MarketHome> createState() => _MarketHomeState();
}

class _MarketHomeState extends State<MarketHome> {
  int _tab = 0;

  void _browse() => setState(() => _tab = 0);

  void _settings() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => DemoSettingsSheet(market: widget.market),
    );
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<AppConnection, AppNetworkState>(
        listenWhen: (before, after) => before.online != after.online,
        listener: (context, _) =>
            context.read<CatalogBloc>().add(const CatalogRefreshed()),
      ),
      BlocListener<ShoppingBloc, ShopState>(
        listenWhen: (before, after) =>
            before.notice != after.notice && after.notice != null,
        listener: (context, state) => ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(state.notice!),
              duration: const Duration(seconds: 2),
            ),
          ),
      ),
      BlocListener<ShoppingBloc, ShopState>(
        listenWhen: (before, after) =>
            before.review != after.review && after.review != null,
        listener: (context, state) {
          context.read<CatalogBloc>().add(const CatalogRefreshed());
          setState(() => _tab = 1);
          unawaited(
            showCheckoutReview(context, state.data!.pending!, state.review!),
          );
        },
      ),
      BlocListener<ShoppingBloc, ShopState>(
        listenWhen: (before, after) =>
            before.data != null &&
            before.data?.lastOrder != after.data?.lastOrder &&
            after.data?.lastOrder != null,
        listener: (context, state) {
          context.read<CatalogBloc>().add(const CatalogRefreshed());
          if (_tab != 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Order ${state.data!.lastOrder!.id} placed.'),
              ),
            );
          }
        },
      ),
    ],
    child: Scaffold(
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: _tab == 0 ? 1120 : 680),
            child: IndexedStack(
              index: _tab,
              children: [
                CatalogScreen(onSettings: _settings),
                ShoppingScreen(
                  saved: false,
                  onBrowse: _browse,
                  onSettings: _settings,
                ),
                ShoppingScreen(
                  saved: true,
                  onBrowse: _browse,
                  onSettings: _settings,
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar:
          BlocSelector<ShoppingBloc, ShopState, ({int cart, int saved})>(
            selector: (state) => (
              cart:
                  state.data?.cart.fold<int>(
                    0,
                    (total, line) => total + line.quantity,
                  ) ??
                  0,
              saved: state.data?.saved.length ?? 0,
            ),
            builder: (context, count) => NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (value) => setState(() => _tab = value),
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.storefront_outlined),
                  selectedIcon: Icon(Icons.storefront_rounded),
                  label: 'Browse',
                ),
                NavigationDestination(
                  icon: Badge.count(
                    count: count.cart,
                    isLabelVisible: count.cart > 0,
                    child: const Icon(Icons.shopping_cart_outlined),
                  ),
                  label: 'Cart',
                ),
                NavigationDestination(
                  icon: Badge.count(
                    count: count.saved,
                    isLabelVisible: count.saved > 0,
                    child: const Icon(Icons.bookmark_border_rounded),
                  ),
                  label: 'Saved',
                ),
              ],
            ),
          ),
    ),
  );
}
