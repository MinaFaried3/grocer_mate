import 'dart:math' as math;

import 'catalog.dart';

class CartLine {
  const CartLine(this.product, this.quantity);
  final Product product;
  final int quantity;

  CartLine withQuantity(int next) => CartLine(product, next);

  factory CartLine.fromJson(Map<String, dynamic> json) =>
      CartLine(Product.fromJson(json['product']), json['quantity']);

  Map<String, Object> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
  };
}

class OrderTotals {
  const OrderTotals({
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.delivery,
  });

  static const freeDeliveryThreshold = 2500;
  final int subtotal;
  final int discount;
  final int tax;
  final int delivery;
  int get total => subtotal - discount + tax + delivery;

  factory OrderTotals.forLines(Iterable<CartLine> lines) {
    var subtotal = 0;
    var discount = 0;
    for (final line in lines) {
      final product = line.product;
      final listPrice = math.max(product.originalPrice, product.price);
      subtotal += listPrice * line.quantity;
      discount += (listPrice - product.price) * line.quantity;
    }
    final net = subtotal - discount;
    return OrderTotals(
      subtotal: subtotal,
      discount: discount,
      tax: (net * 5 + 50) ~/ 100,
      delivery: net == 0 || net >= freeDeliveryThreshold ? 0 : 100,
    );
  }
}

class CheckoutChange {
  const CheckoutChange({
    required this.productId,
    required this.currentPrice,
    required this.available,
  });
  final String productId;
  final int currentPrice;
  final int available;
  bool priceChanged(CartLine line) => line.product.price != currentPrice;
  bool stockChanged(CartLine line) => available < line.quantity;
}

sealed class PurchaseResult {
  const PurchaseResult();
}

class PurchaseReview extends PurchaseResult {
  const PurchaseReview(this.changes);
  final List<CheckoutChange> changes;
}

class OrderReceipt extends PurchaseResult {
  const OrderReceipt({required this.id, required this.total});
  final String id;
  final int total;

  factory OrderReceipt.fromJson(Map<String, dynamic> json) =>
      OrderReceipt(id: json['id'], total: json['total']);

  Map<String, Object> toJson() => {'id': id, 'total': total};
}

class PendingPurchase {
  const PendingPurchase(this.id, this.lines, {this.attempted = false});
  final String id;
  final List<CartLine> lines;
  final bool attempted;

  factory PendingPurchase.fromJson(Map<String, dynamic> json) =>
      PendingPurchase(
        json['id'],
        decodeLines(json['lines']),
        attempted: json['attempted'] == true,
      );

  Map<String, Object> toJson() => {
    'id': id,
    'lines': encodeLines(lines),
    'attempted': attempted,
  };
}

class ShoppingData {
  const ShoppingData({
    this.cart = const [],
    this.saved = const [],
    this.pending,
    this.lastOrder,
  });

  final List<CartLine> cart;
  final List<CartLine> saved;
  final PendingPurchase? pending;
  final OrderReceipt? lastOrder;

  ShoppingData withLists({List<CartLine>? cart, List<CartLine>? saved}) =>
      ShoppingData(
        cart: cart ?? this.cart,
        saved: saved ?? this.saved,
        pending: pending,
        lastOrder: lastOrder,
      );

  factory ShoppingData.fromJson(Map<String, dynamic> json) => ShoppingData(
    cart: decodeLines(json['cart']),
    saved: decodeLines(json['saved']),
    pending: json['pending'] == null
        ? null
        : PendingPurchase.fromJson(json['pending']),
    lastOrder: json['lastOrder'] == null
        ? null
        : OrderReceipt.fromJson(json['lastOrder']),
  );

  Map<String, Object?> toJson() => {
    'cart': encodeLines(cart),
    'saved': encodeLines(saved),
    'pending': pending?.toJson(),
    'lastOrder': lastOrder?.toJson(),
  };
}

List<CartLine> decodeLines(List<dynamic> json) =>
    List<CartLine>.unmodifiable(json.map((item) => CartLine.fromJson(item)));

List<Map<String, Object>> encodeLines(List<CartLine> lines) =>
    lines.map((item) => item.toJson()).toList();

abstract interface class ShoppingRepository {
  Future<ShoppingData> read();
  Future<void> write(ShoppingData data);
}

abstract interface class CheckoutRepository {
  Future<PurchaseResult> purchase(PendingPurchase purchase);
}

class OfflineException implements Exception {
  const OfflineException();
}
