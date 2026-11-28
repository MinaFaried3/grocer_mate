import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import '../../controllers/catalog_bloc.dart';
import '../../controllers/catalog_event.dart';
import '../../controllers/catalog_state.dart';
import 'product_tile.dart';

class const CatalogProductsSection({
  super.key,
  required final CatalogState state,
  required final ValueChanged<String> onProductSelected,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CatalogBloc>();
    return SliverMainAxisGroup(
      slivers: [
        //------------ Products Grid ---------------
        SliverPadding(
          padding: const .symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 260,
              mainAxisExtent:
                  248 +
                  (MediaQuery.textScalerOf(context).scale(14) - 14).clamp(
                        0,
                        40,
                      ) *
                      5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate((context, index) {
              final product = state.products[index];
              return ProductTile(
                product: product,
                onOpen: () => onProductSelected(product.id),
              );
            }, childCount: state.products.length),
          ),
        ),

        //------------ Pagination Footer ---------------
        SliverToBoxAdapter(
          child: Padding(
            padding: const .fromLTRB(20, 14, 20, 24),
            child: Center(
              child: state.loading
                  ? const Padding(
                      padding: .all(10),
                      child: CircularProgressIndicator(),
                    )
                  : state.error != null
                  ? Column(
                      children: [
                        Text(state.error!),
                        OutlinedButton(
                          onPressed: () => bloc.add(const NextPageRequested()),
                          child: const Text('Retry page'),
                        ),
                      ],
                    )
                  : state.hasMore
                  ? OutlinedButton(
                      onPressed: () => bloc.add(const NextPageRequested()),
                      child: const Text('Load more'),
                    )
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
    );
  }
}
