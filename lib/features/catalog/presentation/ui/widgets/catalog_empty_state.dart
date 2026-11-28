import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/widgets/status_panel.dart';

import '../../controllers/catalog_bloc.dart';
import '../../controllers/catalog_event.dart';
import '../../controllers/catalog_state.dart';

class const CatalogEmptyState(final CatalogState state, {super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(
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
            onAction: () =>
                context.read<CatalogBloc>().add(const CatalogRefreshed()),
          )
        : const StatusPanel(
            icon: Icons.search_off_rounded,
            title: 'No groceries found',
            message: 'Try a different search or change your filters.',
          ),
  );
}
