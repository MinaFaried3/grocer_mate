import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/widgets/conditional_builder.dart';
import 'package:grocer_mate/features/app/presentation/controllers/app_connection_cubit.dart';
import 'package:grocer_mate/features/app/presentation/controllers/app_connection_state.dart';
import 'package:grocer_mate/features/shopping/presentation/controllers/shopping_bloc.dart';
import 'package:grocer_mate/features/shopping/presentation/controllers/shopping_state.dart';

import '../../controllers/catalog_bloc.dart';
import '../../controllers/catalog_event.dart';
import '../../controllers/catalog_state.dart';
import '../widgets/catalog_empty_state.dart';
import '../widgets/catalog_header.dart';
import '../widgets/catalog_products_section.dart';

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
    _scroll.removeListener(_maybeLoadNext);
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
            // Check if a new price or stock review arrived.
            final hasNewReview =
                before.review != after.review && after.review != null;

            // Make sure this is not the initial app load from local storage.
            final isNotInitialLoad = before.data != null;

            // Check if a new order receipt was just created.
            final isOrderChanged =
                before.data?.lastOrder != after.data?.lastOrder &&
                after.data?.lastOrder != null;
            final hasNewOrder = isNotInitialLoad && isOrderChanged;

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
      onRefresh: () async => bloc.add(const CatalogRefreshed()),
      child: BlocBuilder<CatalogBloc, CatalogState>(
        builder: (context, state) {
          return CustomScrollView(
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

              //------------ Products or Empty State ---------------
              ConditionalBuilder(
                condition: state.products.isEmpty,
                onTrue: (_) => CatalogEmptyState(state),
                onFalse: (_) => CatalogProductsSection(
                  state: state,
                  onProductSelected: widget.onProductSelected,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
