import 'dart:math' as math;

import 'package:grocer_mate/core/use_case.dart';
import 'package:grocer_mate/features/catalog/domain/entities/catalog.dart';

import '../entities/shopping.dart';

class const AddProduct()
    extends UseCase<({ShoppingData data, Product product}), ShoppingData?> {
  @override
  ShoppingData? call(({ShoppingData data, Product product}) input) {
    final (:data, :product) = input;
    final current = data.cart
        .where((line) => line.product.id == product.id)
        .firstOrNull;
    if ((current?.quantity ?? 0) >= product.stock) return null;
    return data.withLists(
      cart: _merge(data.cart, CartLine(.fromProduct(product), 1)),
    );
  }
}

class const AdjustQuantity()
    extends UseCase<({ShoppingData data, String id, int delta}), ShoppingData> {
  @override
  ShoppingData call(({ShoppingData data, String id, int delta}) input) {
    final (:data, :id, :delta) = input;
    final lines = [
      for (final line in data.cart)
        if (line.product.id != id)
          line
        else
          line.withQuantity(
            (line.quantity + delta).clamp(
              1,
              math.max(line.quantity, line.product.stock),
            ),
          ),
    ];
    return data.withLists(cart: lines);
  }
}

typedef CartItemsInput = ({ShoppingData data, Set<String> ids, bool fromSaved});

class const RemoveItems() extends UseCase<CartItemsInput, ShoppingData> {
  @override
  ShoppingData call(CartItemsInput input) {
    final (:data, :ids, :fromSaved) = input;
    final source = fromSaved ? data.saved : data.cart;
    final remaining = source
        .where((line) => !ids.contains(line.product.id))
        .toList();
    return fromSaved
        ? data.withLists(saved: remaining)
        : data.withLists(cart: remaining);
  }
}

class const MoveItems()
    extends UseCase<CartItemsInput, ({ShoppingData data, bool limited})> {
  @override
  ({ShoppingData data, bool limited}) call(CartItemsInput input) {
    final (:data, :ids, :fromSaved) = input;
    final source = fromSaved ? data.saved : data.cart;
    var target = fromSaved ? data.cart : data.saved;
    final remaining = <CartLine>[];
    var limited = false;
    for (final line in source) {
      final product = line.product;
      if (!ids.contains(product.id)) {
        remaining.add(line);
        continue;
      }
      final existing = target
          .where((other) => other.product.id == product.id)
          .firstOrNull;
      final space = math.max(
        (existing?.product.stock ?? product.stock) - (existing?.quantity ?? 0),
        0,
      );
      final moved = fromSaved ? math.min(space, line.quantity) : line.quantity;
      if (moved > 0) target = _merge(target, line.withQuantity(moved));
      if (moved < line.quantity) {
        remaining.add(line.withQuantity(line.quantity - moved));
        limited = true;
      }
    }
    final updated = fromSaved
        ? data.withLists(cart: target, saved: remaining)
        : data.withLists(cart: remaining, saved: target);
    return (data: updated, limited: limited);
  }
}

class const CancelPendingPurchase()
    extends UseCase<({ShoppingData data, bool underReview}), ShoppingData?> {
  @override
  ShoppingData? call(({ShoppingData data, bool underReview}) input) {
    final (:data, :underReview) = input;
    final purchase = data.pending;
    if (purchase == null || (purchase.attempted && !underReview)) return null;
    var restored = data.cart;
    for (final line in purchase.lines) {
      restored = _merge(restored, line);
    }
    return .new(cart: restored, saved: data.saved, lastOrder: data.lastOrder);
  }
}

List<CartLine> _merge(List<CartLine> lines, CartLine added) {
  final index = lines.indexWhere((line) => line.product.id == added.product.id);
  if (index < 0) return [...lines, added];
  return [...lines]
    ..[index] = lines[index].withQuantity(
      lines[index].quantity + added.quantity,
    );
}
