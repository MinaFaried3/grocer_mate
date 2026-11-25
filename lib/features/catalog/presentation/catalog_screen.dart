import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:grocer_mate/core/theme/market_theme.dart';
import 'package:grocer_mate/core/widgets/market_panels.dart';
import 'package:grocer_mate/core/widgets/product_photo.dart';

import 'catalog_bloc.dart';
import 'product_tile.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, required this.onSettings});
  final VoidCallback onSettings;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadNext);
  }

  void _maybeLoadNext() {
    if (_scroll.position.extentAfter > 360) return;
    final bloc = context.read<CatalogBloc>();
    if (bloc.state.error == null) bloc.add(const NextPageRequested());
  }

  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CatalogBloc>();
    final theme = Theme.of(context);
    return RefreshIndicator(
      onRefresh: () async {
        final finished = bloc.stream.firstWhere((state) => !state.loading);
        bloc.add(const CatalogRefreshed());
        await finished;
      },
      child: BlocBuilder<CatalogBloc, CatalogState>(
        builder: (context, state) {
          final landing =
              state.query.search.isEmpty &&
              !state.query.deals &&
              state.query.category == null &&
              state.query.brand == null;
          return CustomScrollView(
            key: const PageStorageKey('catalog'),
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 15, 20, 17),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: forest,
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: const Icon(
                              Icons.shopping_basket_outlined,
                              color: lime,
                              size: 23,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'GrocerMate',
                              style: theme.textTheme.titleLarge,
                            ),
                          ),
                          IconButton.outlined(
                            tooltip: 'Demo settings',
                            onPressed: widget.onSettings,
                            icon: const Icon(Icons.tune_rounded, size: 21),
                          ),
                        ],
                      ),
                      const SizedBox(height: 17),
                      ListenableBuilder(
                        listenable: _search,
                        builder: (context, _) => TextField(
                          key: const ValueKey('catalog-search'),
                          controller: _search,
                          textInputAction: TextInputAction.search,
                          onChanged: (value) => bloc.add(SearchTyped(value)),
                          decoration: InputDecoration(
                            hintText: 'Search groceries',
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: _search.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Clear search',
                                    onPressed: () {
                                      _search.clear();
                                      bloc.add(const SearchTyped(''));
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                          ),
                        ),
                      ),
                      if (landing) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: _MarketHero(
                            onDeals: () => bloc.add(const DealsSelected()),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        'Shop by category',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 9),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          spacing: 7,
                          children: [
                            ChoiceChip(
                              label: const Text('All'),
                              selected: state.query.category == null,
                              onSelected: (_) =>
                                  bloc.add(const CategorySelected(null)),
                            ),
                            for (final category in state.categories)
                              ChoiceChip(
                                avatar: ExcludeSemantics(
                                  child: Text(category.icon),
                                ),
                                label: Text(category.name),
                                selected: state.query.category == category.id,
                                onSelected: (selected) => bloc.add(
                                  CategorySelected(
                                    selected ? category.id : null,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
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
                              onSelected: (value) => bloc.add(
                                BrandSelected(value.isEmpty ? null : value),
                              ),
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: '',
                                  child: Text('All brands'),
                                ),
                                for (final brand in state.brands)
                                  PopupMenuItem(
                                    value: brand,
                                    child: Text(brand),
                                  ),
                              ],
                              child: Chip(
                                avatar: const Icon(
                                  Icons.filter_list_rounded,
                                  size: 18,
                                ),
                                label: Text(state.query.brand ?? 'Brand'),
                              ),
                            ),
                        ],
                      ),
                      if (state.query.deals)
                        InputChip(
                          label: const Text('On sale'),
                          onDeleted: () => bloc.add(const DealsSelected()),
                        ),
                      if (!state.loading || state.products.isNotEmpty)
                        Text(
                          '${state.total} ${state.total == 1 ? 'product' : 'products'}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (state.products.isEmpty)
                SliverToBoxAdapter(
                  child: state.loading
                      ? const Padding(
                          padding: EdgeInsets.all(45),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : state.error != null
                      ? StatusPanel(
                          icon: Icons.cloud_off_rounded,
                          title: 'Catalog unavailable',
                          message: state.error!,
                          action: 'Try again',
                          onAction: () => bloc.add(const CatalogRefreshed()),
                        )
                      : const StatusPanel(
                          icon: Icons.search_off_rounded,
                          title: 'No groceries found',
                          message:
                              'Try a different search or change your filters.',
                        ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 260,
                      mainAxisExtent:
                          248 +
                          (MediaQuery.textScalerOf(context).scale(14) - 14)
                                  .clamp(0, 40) *
                              5,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          ProductTile(product: state.products[index]),
                      childCount: state.products.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                    child: Center(
                      child: state.loading
                          ? const Padding(
                              padding: EdgeInsets.all(10),
                              child: CircularProgressIndicator(),
                            )
                          : state.error != null
                          ? Column(
                              children: [
                                Text(state.error!),
                                OutlinedButton(
                                  onPressed: () =>
                                      bloc.add(const NextPageRequested()),
                                  child: const Text('Retry page'),
                                ),
                              ],
                            )
                          : state.hasMore
                          ? OutlinedButton(
                              onPressed: () =>
                                  bloc.add(const NextPageRequested()),
                              child: const Text('Load more'),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MarketHero extends StatelessWidget {
  const _MarketHero({required this.onDeals});
  final VoidCallback onDeals;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: ColoredBox(
        color: const Color(0xff15382b),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 640;
            return Stack(
              children: [
                Positioned.fill(
                  left: constraints.maxWidth * (wide ? .32 : .33),
                  child: const ProductPhoto('assets/photos/market.webp'),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xff15382b),
                          const Color(0xff15382b),
                          const Color(0xff15382b).withValues(alpha: .7),
                          Colors.transparent,
                        ],
                        stops: const [0, .31, .48, .71],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 30 : 17,
                    vertical: 19,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Fresh finds,\nbetter prices.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: wide ? 39 : 28,
                          fontWeight: FontWeight.w800,
                          height: 1.06,
                          letterSpacing: -.85,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: onDeals,
                        style: FilledButton.styleFrom(
                          backgroundColor: lime,
                          foregroundColor: const Color(0xff173722),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('Shop deals'),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
