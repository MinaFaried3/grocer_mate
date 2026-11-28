import 'package:grocer_mate/core/network/connection.dart';
import 'package:grocer_mate/core/use_case.dart';

import '../entities/shopping.dart';
import '../repositories/shopping_repository.dart';
import 'cart_operations.dart';

enum SubmissionFailure { offline, retry }

typedef SubmissionResult = ({
  ShoppingData data,
  PurchaseReview? review,
  SubmissionFailure? failure,
  String? notice,
});

class const SubmitPendingPurchase(
  final ShoppingRepository _storage,
  final Future<PurchaseResult> Function(PendingPurchase) _purchase,
) extends UseCase<ShoppingData, Future<SubmissionResult>> {
  @override
  Future<SubmissionResult> call(ShoppingData data) async {
    final pending = data.pending;
    if (pending == null) {
      return (data: data, review: null, failure: null, notice: null);
    }
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
      final result = await _purchase(persisted.pending!);
      switch (result) {
        case PurchaseReview():
          return (data: persisted, review: result, failure: null, notice: null);
        case PartialPurchase():
          final completed = ShoppingData(
            cart: mergePurchaseLines(data.cart, result.missing),
            saved: data.saved,
            lastOrder: result.receipt ?? data.lastOrder,
          );
          await _storage.write(completed);
          return (
            data: completed,
            review: null,
            failure: null,
            notice: result.note ?? 'Available items were ordered. Remaining items are in your cart.',
          );
        case OrderReceipt():
          final completed = ShoppingData(
            cart: data.cart,
            saved: data.saved,
            lastOrder: result,
          );
          await _storage.write(completed);
          return (data: completed, review: null, failure: null, notice: null);
      }
    } on OfflineException {
      return (
        data: persisted,
        review: null,
        failure: SubmissionFailure.offline,
        notice: null,
      );
    } catch (_) {
      return (
        data: persisted,
        review: null,
        failure: SubmissionFailure.retry,
        notice: null,
      );
    }
  }
}
