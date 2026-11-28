import 'package:equatable/equatable.dart';

import 'shopping.dart';

class const CheckoutReviewMemento({
  required final PendingPurchase pending,
  required final PurchaseReview review,
}) extends Equatable {
  List<CheckoutChange> get changes => review.changes;

  List<CartLine> get lines => pending.lines;

  List<CartLine> applyTo(
    List<CartLine> currentLines,
    Map<String, int> quantities,
  ) => review.applyTo(currentLines, quantities);

  List<CartLine> resolve([Map<String, int> quantities = const {}]) =>
      review.applyTo(pending.lines, quantities);

  @override
  List<Object?> get props => [pending, review];
}
