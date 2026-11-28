import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:grocer_mate/core/network/connection.dart';
import 'package:grocer_mate/features/shopping/data/shopping_json.dart';
import 'package:grocer_mate/features/shopping/domain/entities/shopping.dart';
import 'package:grocer_mate/features/shopping/domain/repositories/checkout_repository.dart';
import 'package:grocer_mate/features/shopping/domain/repositories/shopping_repository.dart';
import 'package:grocer_mate/features/shopping/domain/use_cases/submit_pending_purchase.dart';
import 'package:grocer_mate/features/shopping/presentation/controllers/shopping_bloc.dart';
import 'package:grocer_mate/features/shopping/presentation/controllers/shopping_event.dart';

import 'fixtures.dart';

void main() {
  test(
    'calculates the discount, rounded tax and free-delivery threshold in cents',
    () {
      final totals = OrderTotals.forLines([
        CartLine(.fromProduct(milk), 2),
        CartLine(.fromProduct(bread), 1),
      ]);
      expect(
        (
          totals.subtotal,
          totals.discount,
          totals.tax,
          totals.delivery,
          totals.total,
        ),
        (597, 60, 27, 100, 664),
      );
      expect(
        OrderTotals.forLines([CartLine(.fromProduct(bread), 9)]).delivery,
        0,
      );
      expect(OrderTotals.forLines([]).total, 0);
    },
  );

  test(
    'persists bulk moves and applies rapid quantity adjustments in order',
    () async {
      final connection = _Connection(true);
      final storage = _Storage();
      final bloc = ShoppingBloc(
        storage,
        SubmitPendingPurchase(storage, _Checkout().purchase),
        connection,
        createPurchaseId: _purchaseId,
      );
      addTearDown(connection.close);
      addTearDown(bloc.close);

      final ready = bloc.stream.firstWhere((state) => state.data != null);
      bloc.add(const ShopStarted());
      await ready;
      final saved = bloc.stream.firstWhere(
        (state) => state.data!.saved.length == 2,
      );
      bloc
        ..add(const ItemAdded(milk))
        ..add(const ItemAdded(bread))
        ..add(const QuantityAdjusted('milk', 1))
        ..add(const QuantityAdjusted('milk', 1))
        ..add(const ItemsMoved({'milk', 'bread'}, fromSaved: false));
      await saved;
      expect(storage.data.cart, isEmpty);
      expect(storage.data.saved.map((line) => line.quantity), [3, 1]);

      final restored = bloc.stream.firstWhere(
        (state) => state.data!.cart.length == 2,
      );
      bloc.add(const ItemsMoved({'milk', 'bread'}, fromSaved: true));
      await restored;
      expect(storage.data.saved, isEmpty);
      expect(storage.data.cart.map((line) => line.quantity), [3, 1]);
    },
  );

  test('replays a persisted outbox, reviews mixed changes and preserves later cart edits', () async {
    final connection = _Connection(false);
    final storage = _Storage(
      ShoppingData(
        cart: [
          CartLine(.fromProduct(milk), 3),
          CartLine(.fromProduct(bread), 1),
        ],
      ),
    );
    final checkout = _Checkout();
    final first = ShoppingBloc(
      storage,
      SubmitPendingPurchase(storage, checkout.purchase),
      connection,
      createPurchaseId: _purchaseId,
    );
    addTearDown(connection.close);

    final queued = first.stream.firstWhere(
      (state) => state.data?.pending != null,
    );
    first
      ..add(const ShopStarted())
      ..add(const CheckoutRequested());
    final queuedState = await queued;
    final id = queuedState.data!.pending!.id;
    expect(checkout.requests, isEmpty);
    await first.close();

    final restored = ShoppingBloc(
      storage,
      SubmitPendingPurchase(storage, checkout.purchase),
      connection,
      createPurchaseId: () => 'purchase-reviewed',
    );
    addTearDown(restored.close);
    final added = restored.stream.firstWhere(
      (state) => state.data?.cart.isNotEmpty == true,
    );
    restored
      ..add(const ShopStarted())
      ..add(const ItemAdded(bread));
    await added;

    final review = restored.stream.firstWhere((state) => state.review != null);
    connection.setOnline(true);
    final reviewState = await review;
    final changes = reviewState.review!;
    expect(changes.changes, hasLength(2));
    final preview = changes.applyTo(reviewState.data!.pending!.lines, {
      'milk': 1,
    });

    final receipt = restored.stream.firstWhere(
      (state) => state.data?.lastOrder != null,
    );
    restored.add(const CheckoutAccepted({'milk': 1}));
    final finalState = await receipt;
    expect(finalState.review, isNull);
    expect(finalState.notice, isNull);
    expect(finalState.busy, isFalse);
    expect(
      finalState.data!.lastOrder!.total,
      OrderTotals.forLines(preview).total,
    );
    expect(checkout.requests.map((request) => request.id), [
      id,
      'purchase-reviewed',
    ]);
    expect(checkout.requests.last.lines, hasLength(1));
    expect(checkout.requests.last.lines.single.quantity, 1);
    expect(checkout.requests.last.lines.single.product.price, 139);
    expect(storage.data.pending, isNull);
    expect(storage.data.cart.single.product.id, 'bread');
  });

  test(
    'retries an ambiguous checkout with the original idempotency key',
    () async {
      final connection = _Connection(true);
      final storage = _Storage(
        ShoppingData(cart: [CartLine(.fromProduct(milk), 1)]),
      )..failReceiptWrite = true;
      final checkout = _Checkout(review: false);
      final bloc = ShoppingBloc(
        storage,
        SubmitPendingPurchase(storage, checkout.purchase),
        connection,
        createPurchaseId: _purchaseId,
      );
      addTearDown(connection.close);
      addTearDown(bloc.close);

      final failed = bloc.stream.firstWhere(
        (state) => state.notice?.startsWith('Checkout couldn’t') == true,
      );
      bloc
        ..add(const ShopStarted())
        ..add(const CheckoutRequested());
      final result = await failed;
      expect(result.data!.pending!.attempted, isTrue);

      final placed = bloc.stream.firstWhere(
        (state) => state.data?.lastOrder != null,
      );
      bloc
        ..add(const PendingCanceled())
        ..add(const PendingRetried());
      await placed;
      expect(checkout.requests, hasLength(2));
      expect(checkout.requests.first.id, checkout.requests.last.id);
      expect(storage.data.cart, isEmpty);
      expect(storage.data.pending, isNull);
    },
  );
}

String _purchaseId() => 'purchase-1';

class _Storage([var ShoppingData data = const .new()])
    implements ShoppingRepository {
  bool failReceiptWrite = false;

  @override
  Future<ShoppingData> read() async => decodeShopping(encodeShopping(data));

  @override
  Future<void> write(ShoppingData value) async {
    if (value.lastOrder != null && failReceiptWrite) {
      failReceiptWrite = false;
      throw StateError('Storage temporarily unavailable');
    }
    data = decodeShopping(encodeShopping(value));
  }
}

class _Connection(this.online) implements Connection {
  @override
  bool online;

  final _events = StreamController<bool>.broadcast();

  @override
  Stream<bool> get changes => _events.stream;

  void setOnline(bool value) {
    online = value;
    _events.add(value);
  }

  Future<void> close() => _events.close();
}

class _Checkout({final bool review = true}) implements CheckoutRepository {
  final requests = <PendingPurchase>[];

  @override
  Future<PurchaseResult> purchase(PendingPurchase purchase) async {
    requests.add(purchase);
    if (review && requests.length == 1) {
      return const PurchaseReview([
        CheckoutChange(productId: 'milk', currentPrice: 139, available: 2),
        CheckoutChange(productId: 'bread', currentPrice: 279, available: 0),
      ]);
    }
    return OrderReceipt(
      id: 'GM-1001',
      total: OrderTotals.forLines(purchase.lines).total,
    );
  }
}
