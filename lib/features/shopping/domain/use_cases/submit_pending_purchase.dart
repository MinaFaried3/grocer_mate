import 'package:grocer_mate/core/network/connection.dart';
import 'package:grocer_mate/core/use_case.dart';

import '../entities/shopping.dart';
import '../repositories/checkout_repository.dart';
import '../repositories/shopping_repository.dart';

enum SubmissionFailure { offline, retry }

typedef SubmissionResult = ({
  ShoppingData data,
  PurchaseReview? review,
  SubmissionFailure? failure,
});

class const SubmitPendingPurchase(
  final ShoppingRepository _storage,
  final CheckoutRepository _checkout,
) extends UseCase<ShoppingData, Future<SubmissionResult>> {
  @override
  Future<SubmissionResult> call(ShoppingData data) async {
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
          pending: .new(pending.id, pending.lines, attempted: true),
        );
        await _storage.write(marked);
        persisted = marked;
      }
      final result = await _checkout.purchase(persisted.pending!);
      switch (result) {
        case PurchaseReview():
          return (data: persisted, review: result, failure: null);
        case OrderReceipt():
          final completed = ShoppingData(
            cart: data.cart,
            saved: data.saved,
            lastOrder: result,
          );
          await _storage.write(completed);
          return (data: completed, review: null, failure: null);
      }
    } on OfflineException {
      return (
        data: persisted,
        review: null,
        failure: SubmissionFailure.offline,
      );
    } catch (_) {
      return (data: persisted, review: null, failure: SubmissionFailure.retry);
    }
  }
}
