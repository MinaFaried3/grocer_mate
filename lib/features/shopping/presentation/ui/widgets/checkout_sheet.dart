import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/money.dart';
import 'package:grocer_mate/core/theme/theme_context.dart';

import '../../../domain/entities/shopping.dart';
import '../../controllers/shopping_bloc.dart';
import '../../controllers/shopping_event.dart';
import 'checkout_change_panel.dart';

Future<void> showCheckoutReview(
  BuildContext context,
  CheckoutReviewMemento memento,
) {
  final bloc = context.read<ShoppingBloc>();
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => _CheckoutSheet(
      memento: memento,
      onSubmit: (quantities) {
        bloc.add(CheckoutAccepted(quantities));
        Navigator.of(context).pop();
      },
    ),
  );
}

class const _CheckoutSheet({
  required final CheckoutReviewMemento memento,
  required final ValueChanged<Map<String, int>> onSubmit,
}) extends StatefulWidget {
  @override
  State<_CheckoutSheet> createState() => _CheckoutSheetState();
}

class _CheckoutSheetState() extends State<_CheckoutSheet> {
  final _quantities = <String, int>{};

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final memento = widget.memento;
    final changes = {
      for (final change in memento.changes) change.productId: change,
    };
    final adjusted = memento.resolve(_quantities);
    final totals = OrderTotals.forLines(adjusted);

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .78,
        ),
        child: Column(
          mainAxisSize: .min,
          children: [
            //------------ Review Changes List ---------------
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const .fromLTRB(20, 0, 20, 12),
                children: [
                  //------------ Review Instructions ---------------
                  Text(
                    'Review order changes',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Prices or stock changed. Review the updates before placing your order.',
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),

                  //------------ Adjust Changed Items ---------------
                  for (final line in memento.lines)
                    if (changes[line.product.id] case final change?) ...[
                      const SizedBox(height: 12),
                      CheckoutChangePanel(
                        line: line,
                        change: change,
                        selected: change.quantityFor(
                          line,
                          _quantities[line.product.id],
                        ),
                        onChanged: (value) => setState(
                          () => _quantities[line.product.id] = value,
                        ),
                      ),
                    ],
                ],
              ),
            ),

            //------------ Submit Action ---------------
            Padding(
              padding: const .fromLTRB(20, 6, 20, 14),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => widget.onSubmit(.of(_quantities)),
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
