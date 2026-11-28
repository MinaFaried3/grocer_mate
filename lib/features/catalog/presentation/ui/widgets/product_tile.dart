import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/money.dart';
import 'package:grocer_mate/core/theme/market_theme.dart';
import 'package:grocer_mate/core/theme/theme_context.dart';
import 'package:grocer_mate/core/widgets/product_photo.dart';
import 'package:grocer_mate/features/shopping/presentation/controllers/shopping_bloc.dart';
import 'package:grocer_mate/features/shopping/presentation/controllers/shopping_event.dart';

import '../../../domain/entities/catalog.dart';

class const ProductTile({
  super.key,
  required final Product product,
  required final VoidCallback onOpen,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final discount = product.discountPercent;
    final canAdd = context.select(
      (ShoppingBloc bloc) => bloc.state.data != null,
    );
    final stock = switch (product.stock) {
      0 => 'Out of stock',
      <= 8 => 'Only ${product.stock} left',
      _ => 'In stock',
    };

    return Material(
      color: theme.colorScheme.surface,
      clipBehavior: .antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: .circular(15),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: .start,
          children: [
            //------------ Product Image & Badge ---------------
            SizedBox(
              height: 119,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ProductPhoto(product.images.first, cacheWidth: 278),
                  ),
                  if (discount > 0 || product.badges.isNotEmpty)
                    Positioned(
                      top: 9,
                      left: 9,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: discount > 0 ? lime : Colors.white,
                          borderRadius: .circular(7),
                        ),
                        child: Padding(
                          padding: const .symmetric(horizontal: 7, vertical: 3),
                          child: Text(
                            discount > 0 ? '-$discount%' : product.badges.first,
                            style: const TextStyle(
                              fontWeight: .w800,
                              fontSize: 11,
                              color: forest,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            //------------ Product Info & Add Button ---------------
            Expanded(
              child: Padding(
                padding: const .fromLTRB(10, 8, 7, 5),
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      product.brand,
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      product.title,
                      maxLines: 2,
                      overflow: .ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: .w800,
                        height: 1.13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      stock,
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: product.stock == 0
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 4,
                            crossAxisAlignment: .center,
                            children: [
                              Text(
                                money(product.price),
                                style: theme.textTheme.titleMedium,
                              ),
                              if (discount > 0)
                                Text(
                                  money(product.originalPrice),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    decoration: .lineThrough,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Add ${product.title} to cart',
                          onPressed: product.stock > 0 && canAdd
                              ? () => context.read<ShoppingBloc>().add(
                                  ItemAdded(product),
                                )
                              : null,
                          icon: const Icon(Icons.add_rounded, size: 20),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
