import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:grocer_mate/core/widgets/status_panel.dart';

import '../domain/shopping.dart';
import 'cart_summary.dart';
import 'order_receipt_panel.dart';
import 'pending_purchase_panel.dart';
import 'shopping_bloc.dart';
import 'shopping_line_tile.dart';

class const ShoppingScreen({
  super.key,
  required final bool saved,
  required final VoidCallback onBrowse,
  required final VoidCallback onSettings,
}) extends StatefulWidget {
  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final _selection = <String>{};
  bool _selecting = false;

  void _endSelection() => setState(() {
    _selecting = false;
    _selection.clear();
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final saved = widget.saved;
    final bloc = context.read<ShoppingBloc>();
    return BlocBuilder<ShoppingBloc, ShopState>(
      builder: (context, state) {
        final data = state.data;
        final lines = (saved ? data?.saved : data?.cart) ?? const <CartLine>[];
        final selected = _selection.intersection(
          lines.map((line) => line.product.id).toSet(),
        );
        return CustomScrollView(
          key: PageStorageKey(saved ? 'saved' : 'cart'),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              sliver: SliverToBoxAdapter(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        saved ? 'Saved for later' : 'Your cart',
                        style: theme.textTheme.headlineLarge,
                      ),
                    ),
                    IconButton.outlined(
                      tooltip: 'Demo settings',
                      onPressed: widget.onSettings,
                      icon: const Icon(Icons.tune_rounded, size: 21),
                    ),
                  ],
                ),
              ),
            ),
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
                          padding: EdgeInsets.all(36),
                          child: CircularProgressIndicator(),
                        ),
                      ),
              )
            else ...[
              if (!saved && data.pending != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: PendingPurchasePanel(state),
                  ),
                ),
              if (!saved && data.lastOrder != null && data.pending == null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: OrderReceiptPanel(data.lastOrder!),
                  ),
                ),
              if (lines.isEmpty && (saved || data.pending == null))
                SliverToBoxAdapter(
                  child: StatusPanel(
                    icon: saved
                        ? Icons.bookmark_border_rounded
                        : Icons.shopping_bag_outlined,
                    title: saved ? 'Nothing saved yet' : 'Your cart is empty',
                    message: saved
                        ? 'Move items here from your cart to keep them handy.'
                        : 'Pick a few groceries to get started.',
                    action: 'Browse groceries',
                    onAction: widget.onBrowse,
                  ),
                ),
              if (lines.isNotEmpty) ...[
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
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
                if (_selecting)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
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
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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
                if (!saved)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    sliver: SliverToBoxAdapter(child: CartSummary(data)),
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
