import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/shopping.dart';
import '../../domain/use_cases/cart_operations.dart';

part 'shopping_data.g.dart';

@JsonSerializable(explicitToJson: true)
class const ShoppingData({
  final List<CartLine> cart = const [],
  final List<CartLine> saved = const [],
  final PendingPurchase? pending,
  final OrderReceipt? lastOrder,
}) {
  factory fromJson(Json json) => _$ShoppingDataFromJson(json);

  Json toJson() => _$ShoppingDataToJson(this);

  int get cartQty => cart.fold<int>(0, (total, line) => total + line.quantity);

  int get savedQty => saved.length;

  ShoppingData withLists({List<CartLine>? cart, List<CartLine>? saved}) => .new(
    cart: cart ?? this.cart,
    saved: saved ?? this.saved,
    pending: pending,
    lastOrder: lastOrder,
  );

  CheckoutReviewMemento createReviewMemento(PurchaseReview review) =>
      .new(pending: pending!, review: review);

  ShoppingData restoreFromMemento(CheckoutReviewMemento memento) => .new(
    cart: mergePurchaseLines(cart, memento.lines),
    saved: saved,
    lastOrder: lastOrder,
  );

  ShoppingData applyReviewMemento(
    CheckoutReviewMemento memento,
    Map<String, int> quantities,
    String Function() createPurchaseId,
  ) {
    final lines = memento.resolve(quantities);
    return .new(
      cart: cart,
      saved: saved,
      lastOrder: lastOrder,
      pending: lines.isEmpty ? null : .new(createPurchaseId(), lines),
    );
  }
}
