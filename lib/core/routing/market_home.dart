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
    RoutesConstants.home,
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
        //this is for all show notices for all app
        //------------ Notice SnackBar Listener ---------------
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

        //------------ Checkout Review Listener ---------------
        BlocListener<ShoppingBloc, ShopState>(
          listenWhen: (before, after) =>
              before.review != after.review && after.review != null,
          listener: (context, state) {
            context.go(RoutesConstants.cart);
            // Let the Cart route settle before showing the review on top of it.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              unawaited(showCheckoutReview(context, state.review!));
            });
          },
        ),

        //------------ Order Placed Listener ---------------
        BlocListener<ShoppingBloc, ShopState>(
          listenWhen: (before, after) {
            // Make sure this is not the initial app load from local storage.
            final isNotInitialLoad = before.data != null;

            // Check if a new order receipt was just created.
            final isOrderChanged =
                before.data?.lastOrder != after.data?.lastOrder &&
                after.data?.lastOrder != null;
            return isNotInitialLoad && isOrderChanged;
          },
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
        //------------ Body ---------------
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

        //------------ Bottom Navigation Bar ---------------
        bottomNavigationBar:
            BlocSelector<
              ShoppingBloc,
              ShopState,
              ({int cartQty, int savedQty})
            >(
              selector: (state) =>
                  (cartQty: state.cartQty, savedQty: state.savedQty),
              builder: (context, count) => NavigationBar(
                selectedIndex: currentIndex,
                onDestinationSelected: (index) => context.go(_tabs[index]),
                destinations: [
                  //------------ Browse Tab ---------------
                  const NavigationDestination(
                    icon: Icon(Icons.storefront_outlined),
                    selectedIcon: Icon(Icons.storefront_rounded),
                    label: 'Home',
                  ),

                  //------------ Cart Tab ---------------
                  NavigationDestination(
                    icon: Badge.count(
                      count: count.cartQty,
                      isLabelVisible: count.cartQty > 0,
                      child: const Icon(Icons.shopping_cart_outlined),
                    ),
                    label: 'Cart',
                  ),

                  //------------ Saved Tab ---------------
                  NavigationDestination(
                    icon: Badge.count(
                      count: count.savedQty,
                      isLabelVisible: count.savedQty > 0,
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
