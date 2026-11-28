import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/core/theme/theme_context.dart';
import 'package:grocer_mate/core/widgets/status_panel.dart';

import '../../../domain/entities/shopping.dart';
import '../../controllers/shopping_bloc.dart';
import '../../controllers/shopping_event.dart';
import '../../controllers/shopping_state.dart';
import 'shopping_line_tile.dart';

class const ShoppingItemsList({
  super.key,
  required final String storageKey,
  required final String title,
  required final bool saved,
  required final List<CartLine> Function(ShoppingData data) selectLines,
  required final StatusPanel emptyState,
  required final VoidCallback onSettings,
  final List<Widget> Function(ShopState state, ShoppingData data)?
  headerSlivers,
  final Widget Function(ShoppingData data)? footer,
}) extends StatefulWidget {
  @override
  State<ShoppingItemsList> createState() => _ShoppingItemsListState();
}

class _ShoppingItemsListState() extends State<ShoppingItemsList> {
  final _selection = <String>{};
  bool _selecting = false;

  void _endSelection() => setState(() {
    _selecting = false;
    _selection.clear();
  });

  @override
  Widget build(BuildContext context) {
    final saved = widget.saved;
    final bloc = context.read<ShoppingBloc>();
    return BlocBuilder<ShoppingBloc, ShopState>(
      builder: (context, state) {
        final data = state.data;
        final lines = data == null
            ? const <CartLine>[]
            : widget.selectLines(data);
        final selected = _selection.intersection(
          lines.map((line) => line.product.id).toSet(),
        );
        return CustomScrollView(
          key: PageStorageKey(widget.storageKey),
          slivers: [
            //------------ Screen Header & Settings ---------------
            SliverPadding(
              padding: const .fromLTRB(20, 16, 20, 10),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: context.textTheme.headlineLarge,
                      ),
                    ),
                    IconButton.outlined(
                      tooltip: 'Settings',
                      onPressed: widget.onSettings,
                      icon: const Icon(Icons.tune_rounded, size: 21),
                    ),
                  ],
                ),
              ),
            ),

            //------------ Loading or Error State ---------------
            if (data == null)
              SliverToBoxAdapter(
                child: state.loadError
                    ? StatusPanel(
                        icon: Icons.error_outline,
                        title: 'Couldn’t load your lists',
                        message: 'Try opening your cart again.',
                        action: 'Try again',
                        onAction: () => bloc.add(const ShopStarted()),
                      )
                    : const Center(
                        child: Padding(
                          padding: .all(36),
                          child: CircularProgressIndicator(),
                        ),
                      ),
              )
            else ...[
              //------------ Header Slivers & Empty State ---------------
              ...?widget.headerSlivers?.call(state, data),
              if (lines.isEmpty && (saved || data.pending == null))
                SliverToBoxAdapter(child: widget.emptyState),

              if (lines.isNotEmpty) ...[
                //------------ Selection Controls ---------------
                SliverPadding(
                  padding: const .fromLTRB(20, 0, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selecting
                                ? '${selected.length} selected'
                                : '${lines.length} ${lines.length == 1 ? 'product' : 'products'}',
                          ),
                        ),
                        TextButton(
                          onPressed: _selecting
                              ? _endSelection
                              : () => setState(() => _selecting = true),
                          child: Text(
                            _selecting ? 'Cancel selection' : 'Select items',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                //------------ Bulk Selection Actions ---------------
                if (_selecting)
                  SliverPadding(
                    padding: const .fromLTRB(20, 0, 20, 10),
                    sliver: SliverToBoxAdapter(
                      child: Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton(
                            onPressed: () => setState(() {
                              _selection.clear();
                              if (selected.length != lines.length) {
                                _selection.addAll(
                                  lines.map((line) => line.product.id),
                                );
                              }
                            }),
                            child: Text(
                              selected.length == lines.length
                                  ? 'Deselect all'
                                  : 'Select all',
                            ),
                          ),
                          FilledButton.tonal(
                            onPressed: selected.isEmpty
                                ? null
                                : () {
                                    bloc.add(
                                      ItemsMoved(selected, fromSaved: saved),
                                    );
                                    _endSelection();
                                  },
                            child: Text(
                              saved ? 'Move selected to cart' : 'Save selected',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                //------------ Items Sliver List ---------------
                SliverPadding(
                  padding: const .symmetric(horizontal: 20),
                  sliver: SliverList.separated(
                    itemCount: lines.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final line = lines[index];
                      final id = line.product.id;
                      return ShoppingLineTile(
                        key: ValueKey(id),
                        line: line,
                        saved: saved,
                        selecting: _selecting,
                        selected: selected.contains(id),
                        onSelect: (value) => setState(() {
                          if (value) {
                            _selection.add(id);
                          } else {
                            _selection.remove(id);
                          }
                        }),
                      );
                    },
                  ),
                ),

                //------------ Footer Section ---------------
                if (widget.footer != null)
                  SliverPadding(
                    padding: const .fromLTRB(20, 16, 20, 24),
                    sliver: SliverToBoxAdapter(child: widget.footer!(data)),
                  ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ],
        );
      },
    );
  }
}
