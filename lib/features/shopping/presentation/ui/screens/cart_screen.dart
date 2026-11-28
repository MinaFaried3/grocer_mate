import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/widgets/status_panel.dart';

import '../widgets/cart_summary.dart';
import '../widgets/order_receipt_panel.dart';
import '../widgets/pending_purchase_panel.dart';
import '../widgets/shopping_items_list.dart';

class const CartScreen({
  super.key,
  required final VoidCallback onBrowse,
  required final VoidCallback onSettings,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ShoppingItemsList(
    storageKey: 'cart',
    title: 'Your cart',
    saved: false,
    selectLines: (data) => data.cart,
    onSettings: onSettings,

    //------------ Pending & Receipt Banners ---------------
    headerSlivers: (state, data) => [
      if (data.pending != null)
        SliverPadding(
          padding: const .fromLTRB(20, 0, 20, 12),
          sliver: SliverToBoxAdapter(child: PendingPurchasePanel(state)),
        ),
      if (data.lastOrder != null && data.pending == null)
        SliverPadding(
          padding: const .fromLTRB(20, 0, 20, 12),
          sliver: SliverToBoxAdapter(child: OrderReceiptPanel(data.lastOrder!)),
        ),
    ],

    //------------ Empty Cart Panel ---------------
    emptyState: StatusPanel(
      icon: Icons.shopping_bag_outlined,
      title: 'Your cart is empty',
      message: 'Pick a few groceries to get started.',
      action: 'Browse groceries',
      onAction: onBrowse,
    ),

    //------------ Cart Summary Footer ---------------
    footer: CartSummary.new,
  );
}
