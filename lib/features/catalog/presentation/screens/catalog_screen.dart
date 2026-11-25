import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/widgets/status_panel.dart';

import '../controllers/catalog_bloc.dart';
import '../ui/catalog_header.dart';
import '../widgets/product_tile.dart';

class const CatalogScreen({super.key, required final VoidCallback onSettings})
    extends StatefulWidget {
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
    return RefreshIndicator(
      onRefresh: () async {
        final finished = bloc.stream.firstWhere((state) => !state.loading);
        bloc.add(const CatalogRefreshed());
        await finished;
      },
      child: BlocBuilder<CatalogBloc, CatalogState>(
        builder: (context, state) {
          return CustomScrollView(
            key: const PageStorageKey('catalog'),
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              CatalogHeader(
                state: state,
                searchController: _search,
                onSettings: widget.onSettings,
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
