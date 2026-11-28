import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/features/shopping/presentation/controllers/shopping_bloc.dart';
import 'package:grocer_mate/features/shopping/presentation/controllers/shopping_state.dart';
import 'package:grocer_mate/features/shopping/presentation/ui/widgets/checkout_sheet.dart';

import 'routes_constants.dart';

class const MarketHome({
  super.key,
  required final String location,
  required final Widget child,
}) extends StatelessWidget {
  static const _tabs = [
    RoutesConstants.browse,
    RoutesConstants.cart,
    RoutesConstants.saved,
  ];

  int get _currentIndex => switch (location) {
    RoutesConstants.cart => 1,
    RoutesConstants.saved => 2,
    _ => 0,
  };

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex;
    return MultiBlocListener(
      listeners: [
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
            context.go(RoutesConstants.cart);
            // Let the Cart route settle before showing the review on top of it.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              unawaited(
                showCheckoutReview(
                  context,
                  state.data!.pending!,
                  state.review!,
                ),
              );
            });
          },
        ),
        BlocListener<ShoppingBloc, ShopState>(
          listenWhen: (before, after) =>
              before.data != null &&
              before.data?.lastOrder != after.data?.lastOrder &&
              after.data?.lastOrder != null,
          listener: (context, state) {
            if (_currentIndex != 1) {
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
              constraints: BoxConstraints(
                maxWidth: currentIndex == 0 ? 1120 : 680,
              ),
              child: child,
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
                selectedIndex: currentIndex,
                onDestinationSelected: (index) => context.go(_tabs[index]),
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
}
