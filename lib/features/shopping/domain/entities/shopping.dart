import 'dart:math' as math;

import 'package:grocer_mate/core/storage/json_fields.dart';
import 'package:json_annotation/json_annotation.dart';

import 'cart_line.dart';

export '../../data/models/pending_purchase.dart';
export '../../data/models/shopping_data.dart';
export 'cart_line.dart';
export 'cart_product.dart';

part 'shopping.g.dart';

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

@JsonSerializable()
class const OrderReceipt({required final String id, required final int total})
    extends PurchaseResult {
  factory fromJson(Json json) {
    readText(json, 'id');
    readInt(json, 'total');
    return _$OrderReceiptFromJson(json);
  }

  Json toJson() => _$OrderReceiptToJson(this);
}

class const PartialPurchase(
  final List<CartLine> missing, {
  final OrderReceipt? receipt,
  final String? note,
}) extends PurchaseResult;
