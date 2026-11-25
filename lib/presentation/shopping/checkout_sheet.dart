import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/shopping.dart';
import '../widgets/style.dart';
import 'shopping_bloc.dart';

Future<void> showCheckoutReview(
  BuildContext context,
  PendingPurchase pending,
  PurchaseReview review,
) {
  final bloc = context.read<ShoppingBloc>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _CheckoutSheet(
      pending: pending,
      review: review,
      onSubmit: (quantities) {
        bloc.add(CheckoutAccepted(quantities));
        Navigator.of(context).pop();
      },
    ),
  );
}

class _CheckoutSheet extends StatefulWidget {
  const _CheckoutSheet({
    required this.pending,
    required this.review,
    required this.onSubmit,
  });
  final PendingPurchase pending;
  final PurchaseReview review;
  final ValueChanged<Map<String, int>> onSubmit;

  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState extends State<_CheckoutSheet> {
  final _quantities = <String, int>{};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final changes = {
      for (final change in widget.review.changes) change.productId: change,
    };
    final reviewed = widget.pending.lines.where(
      (line) => changes.containsKey(line.product.id),
    );
    int quantity(CartLine line) =>
        _quantities[line.product.id] ??
        math.min(
          changes[line.product.id]?.available ?? line.quantity,
          line.quantity,
        );

    final totals = OrderTotals.forLines([
      for (final line in widget.pending.lines)
        if (quantity(line) > 0)
          CartLine(
            line.product.withAvailability(
              price:
                  changes[line.product.id]?.currentPrice ?? line.product.price,
              stock: changes[line.product.id]?.available ?? line.product.stock,
            ),
            quantity(line),
          ),
    ]);
    final hasItems = widget.pending.lines.any((line) => quantity(line) > 0);

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .78,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                children: [
                  Text(
                    'Review order changes',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Prices or stock changed. Review the updates before placing your order.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  for (final line in reviewed) ...[
                    const SizedBox(height: 12),
                    _ChangePanel(
                      line: line,
                      change: changes[line.product.id]!,
                      selected: quantity(line),
                      onChanged: (value) =>
                          setState(() => _quantities[line.product.id] = value),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => widget.onSubmit(Map.of(_quantities)),
                  child: Text(
                    hasItems
                        ? 'Accept and place order · ${money(totals.total)}'
                        : 'Remove items and cancel',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePanel extends StatelessWidget {
  const _ChangePanel({
    required this.line,
    required this.change,
    required this.selected,
    required this.onChanged,
  });
  final CartLine line;
  final CheckoutChange change;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxQuantity = math.min(line.quantity, change.available);
    return MarketPanel(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(line.product.title, style: theme.textTheme.titleMedium),
          if (change.priceChanged(line))
            Text(
              '${money(line.product.price)} → ${money(change.currentPrice)} each',
            ),
          if (change.stockChanged(line))
            Text(
              change.available == 0
                  ? 'Out of stock · will be removed'
                  : 'Only ${change.available} available · you requested ${line.quantity}',
              style: TextStyle(color: theme.colorScheme.error),
            ),
          if (maxQuantity > 0)
            Row(
              children: [
                Expanded(
                  child: Text(
                    selected == 0 ? 'Will be removed' : 'Keep $selected',
                  ),
                ),
                if (change.stockChanged(line)) ...[
                  IconButton(
                    tooltip: 'Reduce ${line.product.title} quantity',
                    onPressed: selected > 1
                        ? () => onChanged(selected - 1)
                        : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  IconButton(
                    tooltip: 'Increase ${line.product.title} quantity',
                    onPressed: selected > 0 && selected < maxQuantity
                        ? () => onChanged(selected + 1)
                        : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
                TextButton(
                  onPressed: () => onChanged(selected == 0 ? maxQuantity : 0),
                  child: Text(selected == 0 ? 'Keep item' : 'Remove item'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
