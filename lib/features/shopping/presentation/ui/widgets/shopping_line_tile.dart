import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/helpers/money.dart';
import 'package:grocer_mate/core/theme/theme_context.dart';
import 'package:grocer_mate/core/widgets/market_panel.dart';
import 'package:grocer_mate/core/widgets/product_photo.dart';

import '../../../domain/entities/shopping.dart';
import '../../controllers/shopping_bloc.dart';
import '../../controllers/shopping_event.dart';

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
    final textTheme = context.textTheme;
    return MarketPanel(
      padding: const .fromLTRB(12, 10, 8, 8),
      child: Column(
        children: [
          //------------ Product Info & Remove Row ---------------
          Row(
            crossAxisAlignment: .center,
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
                  borderRadius: .circular(11),
                  child: ProductPhoto(product.image, cacheWidth: 112),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(product.title, style: textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      saved
                          ? '${line.quantity} · ${money(product.price)} each'
                          : '${money(product.price)} each',
                      style: textTheme.bodySmall,
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

          //------------ Quantity & Move Actions ---------------
          if (!selecting)
            Wrap(
              alignment: .spaceBetween,
              crossAxisAlignment: .center,
              spacing: 12,
              children: [
                if (!saved)
                  Row(
                    mainAxisSize: .min,
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
                      Text('${line.quantity}', style: textTheme.titleSmall),
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
