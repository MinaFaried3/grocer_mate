import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/app_connection.dart';
import '../../domain/shopping.dart';
import '../widgets/style.dart';
import 'checkout_sheet.dart';
import 'shopping_bloc.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({
    super.key,
    required this.saved,
    required this.onBrowse,
    required this.onSettings,
  });
  final bool saved;
  final VoidCallback onBrowse;
  final VoidCallback onSettings;

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
        final lines = saved
            ? data?.saved ?? <CartLine>[]
            : data?.cart ?? <CartLine>[];
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
                  sliver: SliverToBoxAdapter(child: _PendingPanel(state)),
                ),
              if (!saved && data.lastOrder != null && data.pending == null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: _OrderPanel(data.lastOrder!),
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
                      return _LineTile(
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
                    sliver: SliverToBoxAdapter(child: _CartSummary(data)),
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

class _LineTile extends StatelessWidget {
  const _LineTile({
    super.key,
    required this.line,
    required this.saved,
    required this.selecting,
    required this.selected,
    required this.onSelect,
  });
  final CartLine line;
  final bool saved;
  final bool selecting;
  final bool selected;
  final ValueChanged<bool> onSelect;

  @override
  Widget build(BuildContext context) {
    final product = line.product;
    final id = product.id;
    final bloc = context.read<ShoppingBloc>();
    final theme = Theme.of(context);
    return MarketPanel(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (selecting)
                Checkbox(
                  semanticLabel: 'Select ${product.title}',
                  value: selected,
                  onChanged: (value) => onSelect(value ?? false),
                ),
              SizedBox(
                width: 55,
                height: 55,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: ProductPhoto(product.images.first, cacheWidth: 112),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      saved
                          ? '${line.quantity} · ${money(product.price)} each'
                          : '${money(product.price)} each',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (!selecting)
                IconButton(
                  tooltip: 'Remove ${product.title}',
                  onPressed: () =>
                      bloc.add(ItemsRemoved({id}, fromSaved: saved)),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                ),
            ],
          ),
          if (!selecting)
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              children: [
                if (!saved)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Decrease ${product.title} quantity',
                        onPressed: line.quantity <= 1
                            ? null
                            : () => bloc.add(QuantityAdjusted(id, -1)),
                        icon: const Icon(
                          Icons.remove_circle_outline_rounded,
                          size: 20,
                        ),
                      ),
                      Text(
                        '${line.quantity}',
                        style: theme.textTheme.titleSmall,
                      ),
                      IconButton(
                        tooltip: 'Increase ${product.title} quantity',
                        onPressed: line.quantity >= product.stock
                            ? null
                            : () => bloc.add(QuantityAdjusted(id, 1)),
                        icon: const Icon(
                          Icons.add_circle_outline_rounded,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                TextButton.icon(
                  icon: Icon(
                    saved
                        ? Icons.shopping_cart_outlined
                        : Icons.bookmark_border_rounded,
                    size: 17,
                  ),
                  label: Text(saved ? 'Move to cart' : 'Save for later'),
                  onPressed: () => bloc.add(ItemsMoved({id}, fromSaved: saved)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary(this.data);
  final ShoppingData data;

  @override
  Widget build(BuildContext context) {
    final totals = OrderTotals.forLines(data.cart);
    final theme = Theme.of(context);
    final online = context.select(
      (AppConnection connection) => connection.online,
    );
    return MarketPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Order summary', style: theme.textTheme.titleLarge),
          const SizedBox(height: 10),
          _amount('Subtotal', money(totals.subtotal)),
          _amount(
            'Discount',
            totals.discount == 0 ? money(0) : '-${money(totals.discount)}',
          ),
          _amount('Tax (5%)', money(totals.tax)),
          _amount(
            'Delivery',
            totals.delivery == 0 ? 'Free' : money(totals.delivery),
          ),
          const Divider(height: 19),
          DefaultTextStyle.merge(
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            child: _amount('Total', money(totals.total)),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            key: const ValueKey('buy'),
            onPressed: data.pending != null
                ? null
                : () => context.read<ShoppingBloc>().add(
                    const CheckoutRequested(),
                  ),
            icon: Icon(
              online ? Icons.lock_outline : Icons.cloud_upload_outlined,
              size: 18,
            ),
            label: Text(online ? 'Place order' : 'Queue purchase'),
          ),
        ],
      ),
    );
  }

  Widget _amount(String label, String amount) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text(amount),
      ],
    ),
  );
}

class _PendingPanel extends StatelessWidget {
  const _PendingPanel(this.state);
  final ShopState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final online = context.select(
      (AppConnection connection) => connection.online,
    );
    final bloc = context.read<ShoppingBloc>();
    final pending = state.data!.pending!;
    return MarketPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                state.review != null
                    ? Icons.info_outline
                    : Icons.cloud_upload_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  state.busy
                      ? 'Checking your order'
                      : state.review != null
                      ? 'Order needs your review'
                      : online
                      ? 'Purchase pending'
                      : 'Purchase queued',
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            pending.lines
                .map((line) => '${line.quantity} × ${line.product.title}')
                .join(' · '),
          ),
          if (state.busy) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ] else
            Wrap(
              spacing: 7,
              children: [
                if (state.review != null)
                  FilledButton.tonal(
                    onPressed: () =>
                        showCheckoutReview(context, pending, state.review!),
                    child: const Text('Review changes'),
                  )
                else if (online)
                  FilledButton.tonal(
                    onPressed: () => bloc.add(const PendingRetried()),
                    child: const Text('Retry purchase'),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.only(top: 11),
                    child: Text(
                      'We’ll check prices and stock when you reconnect.',
                    ),
                  ),
                if (!pending.attempted || state.review != null)
                  TextButton(
                    onPressed: () => bloc.add(const PendingCanceled()),
                    child: const Text('Return to cart'),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _OrderPanel extends StatelessWidget {
  const _OrderPanel(this.order);
  final OrderReceipt order;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return MarketPanel(
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colors.primaryContainer,
            foregroundColor: colors.onPrimaryContainer,
            child: const Icon(Icons.check_rounded),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order placed',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('Order ${order.id} · ${money(order.total)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
