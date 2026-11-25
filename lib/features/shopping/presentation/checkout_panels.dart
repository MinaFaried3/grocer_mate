import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/money.dart';
import 'package:grocer_mate/core/network/app_connection.dart';
import 'package:grocer_mate/core/widgets/market_panels.dart';

import '../domain/shopping.dart';
import 'checkout_sheet.dart';
import 'shopping_bloc.dart';

class CartSummary extends StatelessWidget {
  const CartSummary(this.data, {super.key});
  final ShoppingData data;

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
          _amount('Subtotal', money(totals.subtotal)),
          _amount(
            'Discount',
            totals.discount == 0 ? money(0) : '-${money(totals.discount)}',
          ),
          _amount('Tax (5%)', money(totals.tax)),
          _amount(
            'Delivery',
            totals.delivery == 0 ? 'Free' : money(totals.delivery),
          ),
          const Divider(height: 19),
          DefaultTextStyle.merge(
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            child: _amount('Total', money(totals.total)),
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

  Widget _amount(String label, String amount) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(amount),
      ],
    ),
  );
}

class PendingPurchasePanel extends StatelessWidget {
  const PendingPurchasePanel(this.state, {super.key});
  final ShopState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final online = context.select(
      (AppConnection connection) => connection.online,
    );
    final bloc = context.read<ShoppingBloc>();
    final pending = state.data!.pending!;
    return MarketPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                state.review != null
                    ? Icons.info_outline
                    : Icons.cloud_upload_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  state.busy
                      ? 'Checking your order'
                      : state.review != null
                      ? 'Order needs your review'
                      : online
                      ? 'Purchase pending'
                      : 'Purchase queued',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            pending.lines
                .map((line) => '${line.quantity} × ${line.product.title}')
                .join(' · '),
          ),
          if (state.busy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ] else
            Wrap(
              spacing: 7,
              children: [
                if (state.review != null)
                  FilledButton.tonal(
                    onPressed: () =>
                        showCheckoutReview(context, pending, state.review!),
                    child: const Text('Review changes'),
                  )
                else if (online)
                  FilledButton.tonal(
                    onPressed: () => bloc.add(const PendingRetried()),
                    child: const Text('Retry purchase'),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(top: 11),
                    child: Text(
                      'We’ll check prices and stock when you reconnect.',
                    ),
                  ),
                if (!pending.attempted || state.review != null)
                  TextButton(
                    onPressed: () => bloc.add(const PendingCanceled()),
                    child: const Text('Return to cart'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class OrderReceiptPanel extends StatelessWidget {
  const OrderReceiptPanel(this.order, {super.key});
  final OrderReceipt order;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MarketPanel(
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colors.primaryContainer,
            foregroundColor: colors.onPrimaryContainer,
            child: const Icon(Icons.check_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order placed',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('Order ${order.id} · ${money(order.total)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
