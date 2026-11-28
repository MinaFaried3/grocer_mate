import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/widgets/status_panel.dart';
import 'package:grocer_mate/features/app/presentation/controllers/app_connection_cubit.dart';
import 'package:grocer_mate/features/app/presentation/controllers/app_connection_state.dart';
import 'package:grocer_mate/features/shopping/presentation/controllers/shopping_bloc.dart';
import 'package:grocer_mate/features/shopping/presentation/controllers/shopping_state.dart';

import '../../controllers/catalog_bloc.dart';
import '../../controllers/catalog_event.dart';
import '../../controllers/catalog_state.dart';
import '../widgets/catalog_header.dart';
import '../widgets/product_tile.dart';

class const CatalogScreen({
  super.key,
  required final VoidCallback onSettings,
  required final ValueChanged<String> onProductSelected,
}) extends StatefulWidget {
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState() extends State<CatalogScreen> {
  final _search = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _search.text = context.read<CatalogBloc>().state.query.search;
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
    return MultiBlocListener(
      listeners: [
        //i added this to when the connection received the app refresh for the items and qtys
        //------------ Connection Status Listener ---------------
        BlocListener<AppConnectionCubit, AppConnectionState>(
          listenWhen: (before, after) => before.online != after.online,
          listener: (_, _) => bloc.add(const CatalogRefreshed()),
        ),

        //------------ Shopping Review & Order Listener ---------------
        BlocListener<ShoppingBloc, ShopState>(
          listenWhen: (before, after) {
            final hasNewReview =
                before.review != after.review && after.review != null;
            final hasNewOrder =
                before.data != null &&
                before.data?.lastOrder != after.data?.lastOrder &&
                after.data?.lastOrder != null;
            return hasNewReview || hasNewOrder;
          },
          listener: (_, _) => bloc.add(const CatalogRefreshed()),
        ),
      ],
      child: _buildCatalog(bloc),
    );
  }

  Widget _buildCatalog(CatalogBloc bloc) {
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
            keyboardDismissBehavior: .onDrag,
            slivers: [
              //------------ Catalog Header ---------------
              CatalogHeader(
                state: state,
                searchController: _search,
                onSettings: widget.onSettings,
              ),

              //------------ Empty or Error State ---------------
              if (state.products.isEmpty)
                SliverToBoxAdapter(
                  child: state.loading
                      ? const Padding(
                          padding: .all(45),
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
                //------------ Products Grid ---------------
                SliverPadding(
                  padding: const .symmetric(horizontal: 20),
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
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = state.products[index];
                      return ProductTile(
                        product: product,
                        onOpen: () => widget.onProductSelected(product.id),
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
