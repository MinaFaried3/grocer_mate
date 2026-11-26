import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/money.dart';
import 'package:grocer_mate/core/theme/theme_context.dart';
import 'package:grocer_mate/core/widgets/market_panel.dart';

import '../../../domain/entities/shopping.dart';

class const OrderReceiptPanel(final OrderReceipt order, {super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colorScheme;
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
              crossAxisAlignment: .start,
              children: [
                Text('Order placed', style: context.textTheme.titleMedium),
                Text('Order ${order.id} · ${money(order.total)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
