import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:grocer_mate/core/money.dart';
import 'package:grocer_mate/core/network/connection.dart';
import 'package:grocer_mate/core/widgets/status_panel.dart';
import 'package:grocer_mate/core/widgets/product_photo.dart';
import 'package:grocer_mate/features/shopping/presentation/shopping_bloc.dart';

import '../domain/catalog.dart';

class const ProductScreen({
  super.key,
  required final String id,
  required final String title,
}) extends StatefulWidget {
  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late Future<Product> _product;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() =>
      _product = context.read<CatalogRepository>().detail(widget.id);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: FutureBuilder<Product>(
      future: _product,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return StatusPanel(
            icon: Icons.error_outline,
            title: 'Couldn’t open product',
            message: snapshot.error is OfflineException
                ? 'Connect to download product details.'
                : 'Please try again.',
            action: 'Try again',
            onAction: () => setState(_load),
          );
        }
        final product = snapshot.requireData;
        final theme = Theme.of(context);
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                SizedBox(
                  height: 280,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: product.images.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) => SizedBox(
                      width: product.images.length == 1 ? 280 : 255,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: ProductPhoto(product.images[index]),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 19),
                Text(
                  product.brand,
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
                Text(product.title, style: theme.textTheme.headlineLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      money(product.price),
                      style: theme.textTheme.titleLarge,
                    ),
                    if (product.discountPercent > 0)
                      Text(
                        money(product.originalPrice),
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    Text('★ ${product.rating.toStringAsFixed(1)}'),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  product.stock == 0
                      ? 'Out of stock'
                      : '${product.stock} in stock',
                  style: TextStyle(
                    color: product.stock == 0
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text('About this product', style: theme.textTheme.titleLarge),
                const SizedBox(height: 6),
                Text(product.description),
                if (product.nutrition.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Nutrition', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 7,
                    runSpacing: 4,
                    children: [
                      for (final entry in product.nutrition.entries)
                        Chip(label: Text('${entry.key} ${entry.value}')),
                    ],
                  ),
                ],
                if (product.allergens.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Text('Contains ${product.allergens.join(', ')}'),
                ],
                const SizedBox(height: 22),
                BlocSelector<ShoppingBloc, ShopState, bool>(
                  selector: (state) => state.data != null,
                  builder: (context, ready) => FilledButton.icon(
                    onPressed: product.stock == 0 || !ready
                        ? null
                        : () => context.read<ShoppingBloc>().add(
                            ItemAdded(product),
                          ),
                    label: const Text('Add to cart'),
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
