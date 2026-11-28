import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/theme/market_theme.dart';
import 'package:grocer_mate/core/theme/theme_context.dart';

import '../../controllers/catalog_bloc.dart';
import '../../controllers/catalog_event.dart';
import '../../controllers/catalog_state.dart';
import 'market_hero.dart';

class const CatalogHeader({
  super.key,
  required final CatalogState state,
  required final TextEditingController searchController,
  required final VoidCallback onSettings,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CatalogBloc>();
    final theme = context.theme;
    final landing =
        state.query.search.isEmpty &&
        !state.query.deals &&
        state.query.category == null &&
        state.query.brand == null;
    return SliverPadding(
      padding: const .fromLTRB(20, 15, 20, 17),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: .start,
          children: [
            //------------ Top Bar & Settings ---------------
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: forest,
                    borderRadius: .circular(13),
                  ),
                  child: const Icon(
                    Icons.shopping_basket_outlined,
                    color: lime,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('GrocerMate', style: theme.textTheme.titleLarge),
                ),
                IconButton.outlined(
                  tooltip: 'Settings',
                  onPressed: onSettings,
                  icon: const Icon(Icons.tune_rounded, size: 21),
                ),
              ],
            ),
            const SizedBox(height: 17),

            //------------ Search Bar ---------------
            ListenableBuilder(
              listenable: searchController,
              builder: (context, _) => TextField(
                key: const ValueKey('catalog-search'),
                controller: searchController,
                textInputAction: .search,
                onChanged: (value) => bloc.add(SearchTyped(value)),
                decoration: InputDecoration(
                  hintText: 'Search groceries',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () {
                            searchController.clear();
                            bloc.add(const SearchTyped(''));
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),

            //------------ Market Hero Banner ---------------
            if (landing) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: MarketHero(
                  onDeals: () => bloc.add(const DealsSelected()),
                ),
              ),
            ],
            const SizedBox(height: 18),

            //------------ Category Filters ---------------
            Text('Shop by category', style: theme.textTheme.titleLarge),
            const SizedBox(height: 9),
            SingleChildScrollView(
              scrollDirection: .horizontal,
              child: Row(
                spacing: 7,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: state.query.category == null,
                    onSelected: (_) => bloc.add(const CategorySelected(null)),
                  ),
                  for (final category in state.categories)
                    ChoiceChip(
                      avatar: ExcludeSemantics(child: Text(category.icon)),
                      label: Text(category.name),
                      selected: state.query.category == category.id,
                      onSelected: (selected) => bloc.add(
                        CategorySelected(selected ? category.id : null),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            //------------ Section Title & Brand Filter ---------------
            Row(
              children: [
                Expanded(
                  child: Text(
                    state.query.search.isNotEmpty
                        ? 'Search results'
                        : state.query.deals
                        ? 'Today’s deals'
                        : 'Groceries',
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                if (state.brands.isNotEmpty)
                  PopupMenuButton<String>(
                    tooltip: 'Filter by brand',
                    initialValue: state.query.brand ?? '',
                    onSelected: (value) =>
                        bloc.add(BrandSelected(value.isEmpty ? null : value)),
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: '', child: Text('All brands')),
                      for (final brand in state.brands)
                        PopupMenuItem(value: brand, child: Text(brand)),
                    ],
                    child: Chip(
                      avatar: const Icon(Icons.filter_list_rounded, size: 18),
                      label: Text(state.query.brand ?? 'Brand'),
                    ),
                  ),
              ],
            ),

            //------------ Deals Chip & Product Count ---------------
            if (state.query.deals)
              InputChip(
                label: const Text('On sale'),
                onDeleted: () => bloc.add(const DealsSelected()),
              ),
            if (!state.loading || state.products.isNotEmpty)
              Text(
                '${state.total} ${state.total == 1 ? 'product' : 'products'}',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
          ],
        ),
      ),
    );
  }
}
