import 'dart:math' as math;

import 'cart_product.dart';

class const CartLine(final CartProduct product, final int quantity) {
  this : assert(quantity > 0);

  CartLine withQuantity(int next) => .new(product, next);
}

class const OrderTotals({
  required final int subtotal,
  required final int discount,
  required final int tax,
  required final int delivery,
}) {
  static const freeDeliveryThreshold = 2500;

  int get total => subtotal - discount + tax + delivery;

  factory forLines(Iterable<CartLine> lines) {
    var subtotal = 0;
    var discount = 0;
    for (final line in lines) {
      final product = line.product;
      final listPrice = math.max(product.originalPrice, product.price);
      subtotal += listPrice * line.quantity;
      discount += (listPrice - product.price) * line.quantity;
    }
    final net = subtotal - discount;
    return .new(
      subtotal: subtotal,
      discount: discount,
      tax: (net * 5 + 50) ~/ 100,
      delivery: net == 0 || net >= freeDeliveryThreshold ? 0 : 100,
    );
  }
}

class const CheckoutChange({
  required final String productId,
  required final int currentPrice,
  required final int available,
}) {
  bool priceChanged(CartLine line) => line.product.price != currentPrice;
  bool stockChanged(CartLine line) => available < line.quantity;

  int quantityFor(CartLine line, [int? requested]) {
    final maxQuantity = math.min(line.quantity, available);
    return (requested ?? maxQuantity).clamp(0, maxQuantity);
  }
}

sealed class const PurchaseResult();

class const PurchaseReview(final List<CheckoutChange> changes)
    extends PurchaseResult {
  List<CartLine> applyTo(List<CartLine> lines, Map<String, int> quantities) {
    final changesById = {
      for (final change in changes) change.productId: change,
    };
    final adjusted = <CartLine>[];
    for (final line in lines) {
      final id = line.product.id;
      final change = changesById[id];
      if (change == null) {
        adjusted.add(line);
        continue;
      }
      final quantity = change.quantityFor(line, quantities[id]);
      if (quantity == 0) continue;
      adjusted.add(
        .new(
          line.product.withAvailability(
            price: change.currentPrice,
            stock: change.available,
          ),
          quantity,
        ),
      );
    }
    return adjusted;
  }
}

class const OrderReceipt({required final String id, required final int total})
    extends PurchaseResult;

class const PendingPurchase(
  final String id,
  final List<CartLine> lines, {
  final bool attempted = false,
});

class const ShoppingData({
  final List<CartLine> cart = const [],
  final List<CartLine> saved = const [],
  final PendingPurchase? pending,
  final OrderReceipt? lastOrder,
}) {
  ShoppingData withLists({List<CartLine>? cart, List<CartLine>? saved}) => .new(
    cart: cart ?? this.cart,
    saved: saved ?? this.saved,
    pending: pending,
    lastOrder: lastOrder,
  );
}

abstract interface class ShoppingRepository {
  Future<ShoppingData> read();
  Future<void> write(ShoppingData data);
}

abstract interface class CheckoutRepository {
  Future<PurchaseResult> purchase(PendingPurchase purchase);
}
