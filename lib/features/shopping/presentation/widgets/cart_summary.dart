import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/money.dart';
import 'package:grocer_mate/core/network/app_connection.dart';
import 'package:grocer_mate/core/widgets/market_panel.dart';

import '../../domain/shopping.dart';
import '../controllers/shopping_bloc.dart';
import 'order_amount_row.dart';

class const CartSummary(final ShoppingData data, {super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final totals = OrderTotals.forLines(data.cart);
    final theme = Theme.of(context);
    final online = context.select(
      (AppConnection connection) => connection.online,
    );
    return MarketPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Order summary', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          OrderAmountRow('Subtotal', money(totals.subtotal)),
          OrderAmountRow(
            'Discount',
            totals.discount == 0 ? money(0) : '-${money(totals.discount)}',
          ),
          OrderAmountRow('Tax (5%)', money(totals.tax)),
          OrderAmountRow(
            'Delivery',
            totals.delivery == 0 ? 'Free' : money(totals.delivery),
          ),
          const Divider(height: 19),
          DefaultTextStyle.merge(
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            child: OrderAmountRow('Total', money(totals.total)),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('buy'),
            onPressed: data.pending != null
                ? null
                : () => context.read<ShoppingBloc>().add(
                    const CheckoutRequested(),
                  ),
            icon: Icon(
              online ? Icons.lock_outline : Icons.cloud_upload_outlined,
              size: 18,
            ),
            label: Text(online ? 'Place order' : 'Queue purchase'),
          ),
        ],
      ),
    );
  }
}
