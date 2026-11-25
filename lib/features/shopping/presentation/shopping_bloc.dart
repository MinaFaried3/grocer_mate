import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import 'package:grocer_mate/core/network/connection.dart';
import 'package:grocer_mate/features/catalog/domain/catalog.dart';

import '../domain/shopping.dart';

sealed class ShopEvent {
  const ShopEvent();
}

class ShopStarted extends ShopEvent {
  const ShopStarted();
}

class ItemAdded extends ShopEvent {
  const ItemAdded(this.product);
  final Product product;
}

class QuantityAdjusted extends ShopEvent {
  const QuantityAdjusted(this.id, this.delta);
  final String id;
  final int delta;
}

class ItemsMoved extends ShopEvent {
  const ItemsMoved(this.ids, {required this.fromSaved});
  final Set<String> ids;
  final bool fromSaved;
}

class ItemsRemoved extends ShopEvent {
  const ItemsRemoved(this.ids, {required this.fromSaved});
  final Set<String> ids;
  final bool fromSaved;
}

class CheckoutRequested extends ShopEvent {
  const CheckoutRequested();
}

class PendingRetried extends ShopEvent {
  const PendingRetried();
}

class PendingCanceled extends ShopEvent {
  const PendingCanceled();
}

class CheckoutAccepted extends ShopEvent {
  const CheckoutAccepted(this.quantities);
  final Map<String, int> quantities;
}

class ShopState {
  const ShopState({
    this.data,
    this.busy = false,
    this.loadError = false,
    this.review,
    this.notice,
  });

  final ShoppingData? data;
  final bool busy;
  final bool loadError;
  final PurchaseReview? review;
  final String? notice;
}

class ShoppingBloc extends Bloc<ShopEvent, ShopState> {
  ShoppingBloc(this._storage, this._checkout, this._connection)
    : super(const ShopState()) {
    on<ShopEvent>(
      _handle,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
    _subscription = _connection.changes.listen((online) {
      if (online) add(const PendingRetried());
    });
  }

  final ShoppingRepository _storage;
  final CheckoutRepository _checkout;
  final Connection _connection;
  late final StreamSubscription<bool> _subscription;

  Future<void> _handle(ShopEvent event, Emitter<ShopState> emit) async {
    if (event is ShopStarted) {
      if (state.data != null) return;
      emit(const ShopState());
      try {
        final data = await _storage.read();
        emit(ShopState(data: data));
        if (data.pending != null) await _submit(data, emit);
      } catch (_) {
        emit(const ShopState(loadError: true));
      }
      return;
    }
    final data = state.data;
    if (data == null) return;
    try {
      switch (event) {
        case ShopStarted():
          break;
        case ItemAdded(:final product):
          await _addItem(data, product, emit);
        case QuantityAdjusted(:final id, :final delta):
          await _adjustQuantity(data, id, delta, emit);
        case ItemsMoved(:final ids, :final fromSaved):
          await _move(data, ids, fromSaved: fromSaved, emit: emit);
        case ItemsRemoved(:final ids, :final fromSaved):
          final updated = fromSaved
              ? data.withLists(
                  saved: data.saved
                      .where((line) => !ids.contains(line.product.id))
                      .toList(),
                )
              : data.withLists(
                  cart: data.cart
                      .where((line) => !ids.contains(line.product.id))
                      .toList(),
                );
          await _save(updated, emit, review: state.review);
        case CheckoutRequested():
          if (data.pending != null || data.cart.isEmpty) return;
          final request = PendingPurchase(const Uuid().v4(), data.cart);
          final updated = ShoppingData(
            saved: data.saved,
            pending: request,
            lastOrder: data.lastOrder,
          );
          await _save(
            updated,
            emit,
            notice: _connection.online
                ? null
                : 'Purchase queued for when you’re online.',
          );
          await _submit(updated, emit);
        case PendingRetried():
          if (state.review == null) await _submit(data, emit);
        case PendingCanceled():
          final pending = data.pending;
          if (pending == null || (pending.attempted && state.review == null)) {
            return;
          }
          var cart = data.cart;
          for (final line in pending.lines) {
            cart = _merge(cart, line);
          }
          await _save(
            ShoppingData(
              cart: cart,
              saved: data.saved,
              lastOrder: data.lastOrder,
            ),
            emit,
            notice: 'Purchase returned to your cart.',
          );
        case CheckoutAccepted(:final quantities):
          await _accept(data, quantities, emit);
      }
    } catch (_) {
      emit(
        ShopState(
          data: state.data,
          review: state.review,
          notice: 'We couldn’t save that change. Please try again.',
        ),
      );
    }
  }

  Future<void> _addItem(
    ShoppingData data,
    Product product,
    Emitter<ShopState> emit,
  ) async {
    final current = data.cart
        .where((line) => line.product.id == product.id)
        .firstOrNull;
    if ((current?.quantity ?? 0) >= product.stock) {
      emit(
        ShopState(
          data: data,
          review: state.review,
          notice: 'You’ve reached the available quantity.',
        ),
      );
      return;
    }
    await _save(
      data.withLists(cart: _merge(data.cart, CartLine(product, 1))),
      emit,
      review: state.review,
      notice: 'Added to cart.',
    );
  }

  Future<void> _adjustQuantity(
    ShoppingData data,
    String id,
    int delta,
    Emitter<ShopState> emit,
  ) async {
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
    await _save(data.withLists(cart: lines), emit, review: state.review);
  }

  Future<void> _move(
    ShoppingData data,
    Set<String> ids, {
    required bool fromSaved,
    required Emitter<ShopState> emit,
  }) async {
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
    await _save(
      updated,
      emit,
      review: state.review,
      notice: limited
          ? 'Unavailable quantities are still saved.'
          : fromSaved
          ? 'Moved to cart.'
          : 'Saved for later.',
    );
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

  Future<void> _accept(
    ShoppingData data,
    Map<String, int> quantities,
    Emitter<ShopState> emit,
  ) async {
    final pending = data.pending;
    final review = state.review;
    if (pending == null || review == null) return;
    final lines = review.applyTo(pending.lines, quantities);
    final updated = ShoppingData(
      cart: data.cart,
      saved: data.saved,
      lastOrder: data.lastOrder,
      pending: lines.isEmpty ? null : PendingPurchase(pending.id, lines),
    );
    await _save(
      updated,
      emit,
      notice: lines.isEmpty
          ? 'The purchase was canceled because no items remain.'
          : null,
    );
    await _submit(updated, emit);
  }

  Future<void> _submit(ShoppingData data, Emitter<ShopState> emit) async {
    final pending = data.pending;
    if (pending == null || !_connection.online) return;
    var submittedData = data;
    emit(ShopState(data: data, busy: true));
    try {
      if (!pending.attempted) {
        // Record the attempt before sending it so an interrupted purchase can retry safely.
        final marked = ShoppingData(
          cart: data.cart,
          saved: data.saved,
          pending: PendingPurchase(pending.id, pending.lines, attempted: true),
          lastOrder: data.lastOrder,
        );
        await _storage.write(marked);
        submittedData = marked;
      }
      final result = await _checkout.purchase(submittedData.pending!);
      switch (result) {
        case PurchaseReview():
          emit(ShopState(data: submittedData, review: result));
        case OrderReceipt():
          await _save(
            ShoppingData(cart: data.cart, saved: data.saved, lastOrder: result),
            emit,
          );
      }
    } on OfflineException {
      emit(
        ShopState(
          data: submittedData,
          notice: 'Purchase queued for when you’re online.',
        ),
      );
    } catch (_) {
      emit(
        ShopState(
          data: submittedData,
          notice: 'Checkout couldn’t finish. Your purchase is saved for retry.',
        ),
      );
    }
  }

  Future<void> _save(
    ShoppingData data,
    Emitter<ShopState> emit, {
    PurchaseReview? review,
    String? notice,
  }) async {
    await _storage.write(data);
    emit(ShopState(data: data, review: review, notice: notice));
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
