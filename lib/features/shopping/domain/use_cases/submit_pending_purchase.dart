import 'package:grocer_mate/core/network/connection.dart';

import '../shopping.dart';

enum SubmissionFailure { offline, retry }

typedef SubmissionResult = ({
  ShoppingData data,
  PurchaseReview? review,
  SubmissionFailure? failure,
});

Future<SubmissionResult> submitPendingPurchase(
  ShoppingData data,
  ShoppingRepository storage,
  CheckoutRepository checkout,
) async {
  final pending = data.pending;
  if (pending == null) return (data: data, review: null, failure: null);
  var persisted = data;
  try {
    if (!pending.attempted) {
      // Persist the attempt before sending. A retry must reuse this purchase ID.
      final marked = ShoppingData(
        cart: data.cart,
        saved: data.saved,
        lastOrder: data.lastOrder,
        pending: PendingPurchase(pending.id, pending.lines, attempted: true),
      );
      await storage.write(marked);
      persisted = marked;
    }
    final result = await checkout.purchase(persisted.pending!);
    switch (result) {
      case PurchaseReview():
        return (data: persisted, review: result, failure: null);
      case OrderReceipt():
        final completed = ShoppingData(
          cart: data.cart,
          saved: data.saved,
          lastOrder: result,
        );
        await storage.write(completed);
        return (data: completed, review: null, failure: null);
    }
  } on OfflineException {
    return (data: persisted, review: null, failure: SubmissionFailure.offline);
  } catch (_) {
    return (data: persisted, review: null, failure: SubmissionFailure.retry);
  }
}
