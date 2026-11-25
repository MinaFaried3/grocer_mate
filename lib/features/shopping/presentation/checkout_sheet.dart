import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:grocer_mate/core/money.dart';

import '../domain/shopping.dart';
import 'checkout_change_panel.dart';
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

class const _CheckoutSheet({
  required final PendingPurchase pending,
  required final PurchaseReview review,
  required final ValueChanged<Map<String, int>> onSubmit,
}) extends StatefulWidget {
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
    final reviewed = [
      for (final line in widget.pending.lines)
        if (changes[line.product.id] case final CheckoutChange change)
          (line, change),
    ];
    final adjusted = widget.review.applyTo(widget.pending.lines, _quantities);
    final totals = OrderTotals.forLines(adjusted);

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
                  for (final (line, change) in reviewed) ...[
                    const SizedBox(height: 12),
                    CheckoutChangePanel(
                      line: line,
                      change: change,
                      selected: change.quantityFor(
                        line,
                        _quantities[line.product.id],
                      ),
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
                    adjusted.isNotEmpty
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
