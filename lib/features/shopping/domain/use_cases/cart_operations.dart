import 'dart:math' as math;

import 'package:grocer_mate/features/catalog/domain/catalog.dart';

import '../shopping.dart';

extension CartOperations on ShoppingData {
  ShoppingData? addProduct(Product product) {
    final current = cart
        .where((line) => line.product.id == product.id)
        .firstOrNull;
    if ((current?.quantity ?? 0) >= product.stock) return null;
    return withLists(cart: _merge(cart, CartLine(.fromProduct(product), 1)));
  }

  ShoppingData adjustQuantity(String id, int delta) {
    final lines = [
      for (final line in cart)
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
    return withLists(cart: lines);
  }

  ShoppingData removeItems(Set<String> ids, {required bool fromSaved}) {
    final source = fromSaved ? saved : cart;
    final remaining = source
        .where((line) => !ids.contains(line.product.id))
        .toList();
    return fromSaved ? withLists(saved: remaining) : withLists(cart: remaining);
  }

  ({ShoppingData data, bool limited}) moveItems(
    Set<String> ids, {
    required bool fromSaved,
  }) {
    final source = fromSaved ? saved : cart;
    var target = fromSaved ? cart : saved;
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
        ? withLists(cart: target, saved: remaining)
        : withLists(cart: remaining, saved: target);
    return (data: updated, limited: limited);
  }

  ShoppingData? cancelPending({required bool underReview}) {
    final purchase = pending;
    if (purchase == null || (purchase.attempted && !underReview)) return null;
    var restored = cart;
    for (final line in purchase.lines) {
      restored = _merge(restored, line);
    }
    return .new(cart: restored, saved: saved, lastOrder: lastOrder);
  }

  List<CartLine> _merge(List<CartLine> lines, CartLine added) {
    final index = lines.indexWhere(
      (line) => line.product.id == added.product.id,
    );
    if (index < 0) return [...lines, added];
    return [...lines]
      ..[index] = lines[index].withQuantity(
        lines[index].quantity + added.quantity,
      );
  }
}
