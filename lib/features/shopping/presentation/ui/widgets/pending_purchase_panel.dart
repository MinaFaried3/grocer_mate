import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

import 'package:grocer_mate/features/app/presentation/controllers/app_connection_cubit.dart';
import 'package:grocer_mate/core/theme/theme_context.dart';
import 'package:grocer_mate/core/widgets/market_panel.dart';

import '../../controllers/shopping_bloc.dart';
import '../../controllers/shopping_event.dart';
import '../../controllers/shopping_state.dart';
import 'checkout_sheet.dart';

class const PendingPurchasePanel(final ShopState state, {super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final online = context.select(
      (AppConnectionCubit connection) => connection.online,
    );
    final bloc = context.read<ShoppingBloc>();
    final pending = state.data!.pending!;
    return MarketPanel(
      child: Column(
        crossAxisAlignment: .start,
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
                    padding: .only(top: 11),
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
