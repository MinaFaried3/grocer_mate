import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/money.dart';
import 'package:grocer_mate/core/widgets/market_panel.dart';

import '../../domain/shopping.dart';

class const CheckoutChangePanel({
  super.key,
  required final CartLine line,
  required final CheckoutChange change,
  required final int selected,
  required final ValueChanged<int> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxQuantity = change.quantityFor(line);
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
