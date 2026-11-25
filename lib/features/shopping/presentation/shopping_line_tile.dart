import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/money.dart';
import 'package:grocer_mate/core/widgets/market_panel.dart';
import 'package:grocer_mate/core/widgets/product_photo.dart';

import '../domain/shopping.dart';
import 'shopping_bloc.dart';

class const ShoppingLineTile({
  super.key,
  required final CartLine line,
  required final bool saved,
  required final bool selecting,
  required final bool selected,
  required final ValueChanged<bool> onSelect,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final product = line.product;
    final id = product.id;
    final bloc = context.read<ShoppingBloc>();
    final theme = Theme.of(context);
    return MarketPanel(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (selecting)
                Checkbox(
                  semanticLabel: 'Select ${product.title}',
                  value: selected,
                  onChanged: (value) => onSelect(value ?? false),
                ),
              SizedBox(
                width: 55,
                height: 55,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: ProductPhoto(product.images.first, cacheWidth: 112),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      saved
                          ? '${line.quantity} · ${money(product.price)} each'
                          : '${money(product.price)} each',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (!selecting)
                IconButton(
                  tooltip: 'Remove ${product.title}',
                  onPressed: () =>
                      bloc.add(ItemsRemoved({id}, fromSaved: saved)),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                ),
            ],
          ),
          if (!selecting)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              children: [
                if (!saved)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Decrease ${product.title} quantity',
                        onPressed: line.quantity <= 1
                            ? null
                            : () => bloc.add(QuantityAdjusted(id, -1)),
                        icon: const Icon(
                          Icons.remove_circle_outline_rounded,
                          size: 20,
                        ),
                      ),
                      Text(
                        '${line.quantity}',
                        style: theme.textTheme.titleSmall,
                      ),
                      IconButton(
                        tooltip: 'Increase ${product.title} quantity',
                        onPressed: line.quantity >= product.stock
                            ? null
                            : () => bloc.add(QuantityAdjusted(id, 1)),
                        icon: const Icon(
                          Icons.add_circle_outline_rounded,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                TextButton.icon(
                  icon: Icon(
                    saved
                        ? Icons.shopping_cart_outlined
                        : Icons.bookmark_border_rounded,
                    size: 17,
                  ),
                  label: Text(saved ? 'Move to cart' : 'Save for later'),
                  onPressed: () => bloc.add(ItemsMoved({id}, fromSaved: saved)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
