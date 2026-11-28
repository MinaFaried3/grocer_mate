import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/shopping.dart';
import '../../domain/repositories/shopping_repository.dart';
import '../../domain/use_cases/cart_operations.dart';
import '../../domain/use_cases/submit_pending_purchase.dart';
import 'shopping_event.dart';
import 'shopping_state.dart';

class ShoppingBloc(
  final ShoppingRepository _repo,
  final SubmitPendingPurchase _submitPendingPurchase,
  final bool Function() _isOnline, {
  required Stream<bool> connectionChanges,
  required final String Function() createPurchaseId,
}) extends Bloc<ShopEvent, ShopState> {
  this : super(const .new()) {
    on<ShopEvent>(
      _handle,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
    _subscription = connectionChanges.listen((online) {
      if (online) add(const PendingRetried());
    });
  }

  static const _addProduct = AddProduct();
  static const _adjustQuantity = AdjustQuantity();
  static const _moveItems = MoveItems();
  static const _removeItems = RemoveItems();
  static const _cancelPendingPurchase = CancelPendingPurchase();

  late final StreamSubscription<bool> _subscription;

  Future<void> _handle(ShopEvent event, Emitter<ShopState> emit) async {
    if (event is ShopStarted) {
      if (state.data != null) return;
      emit(const .new());
      try {
        final data = await _repo.read();
        emit(state.copyWith(data: data));
        if (data.pending != null) await _submit(data, emit);
      } catch (_) {
        emit(const .new(loadError: true));
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
          final updated = _addProduct((data: data, product: product));
          if (updated == null) {
            emit(
              state.copyWith(notice: 'You’ve reached the available quantity.'),
            );
          } else {
            await _save(updated, emit, notice: 'Added to cart.');
          }
        case QuantityAdjusted(:final id, :final delta):
          await _save(
            _adjustQuantity((data: data, id: id, delta: delta)),
            emit,
          );
        case ItemsMoved(:final ids, :final fromSaved):
          final moved = _moveItems((
            data: data,
            ids: ids,
            fromSaved: fromSaved,
          ));
          await _save(
            moved.data,
            emit,
            notice: moved.limited
                ? 'Unavailable quantities are still saved.'
                : fromSaved
                ? 'Moved to cart.'
                : 'Saved for later.',
          );
        case ItemsRemoved(:final ids, :final fromSaved):
          await _save(
            _removeItems((data: data, ids: ids, fromSaved: fromSaved)),
            emit,
          );
        case CheckoutRequested():
          if (data.pending != null || data.cart.isEmpty) return;
          final request = PendingPurchase(createPurchaseId(), data.cart);
          final updated = ShoppingData(
            saved: data.saved,
            pending: request,
            lastOrder: data.lastOrder,
          );
          await _save(
            updated,
            emit,
            notice: _isOnline()
                ? null
                : 'Purchase queued for when you’re online.',
          );
          await _submit(updated, emit);
        case PendingRetried():
          if (state.review == null) await _submit(data, emit);
        case PendingCanceled():
          final review = state.review;
          final restored = review != null
              ? data.restoreFromMemento(review)
              : _cancelPendingPurchase((data: data, underReview: false));
          if (restored == null) return;
          await _save(
            restored,
            emit,
            clearReview: true,
            notice: 'Purchase returned to your cart.',
          );
        case CheckoutAccepted(:final quantities):
          await _accept(data, quantities, emit);
      }
    } catch (_) {
      emit(
        state.copyWith(
          notice: 'We couldn’t save that change. Please try again.',
        ),
      );
    }
  }

  Future<void> _accept(
    ShoppingData data,
    Map<String, int> quantities,
    Emitter<ShopState> emit,
  ) async {
    final review = state.review;
    if (data.pending == null || review == null) return;
    final updated = data.applyReviewMemento(
      review,
      quantities,
      createPurchaseId,
    );
    await _save(
      updated,
      emit,
      clearReview: true,
      notice: updated.pending == null
          ? 'The purchase was canceled because no items remain.'
          : null,
    );
    await _submit(updated, emit);
  }

  Future<void> _submit(ShoppingData data, Emitter<ShopState> emit) async {
    final pending = data.pending;
    if (pending == null || !_isOnline()) return;
    emit(state.copyWith(busy: true, clearReview: true, clearNotice: true));
    final result = await _submitPendingPurchase(data);
    final notice = switch (result.failure) {
      .offline => 'Purchase queued for when you’re online.',
      .retry => 'Checkout couldn’t finish. Your purchase is saved for retry.',
      null => result.notice,
    };
    emit(
      state.copyWith(
        data: result.data,
        busy: false,
        review: result.review,
        notice: notice,
      ),
    );
  }

  Future<void> _save(
    ShoppingData data,
    Emitter<ShopState> emit, {
    bool clearReview = false,
    String? notice,
  }) async {
    await _repo.write(data);
    emit(
      state.copyWith(
        data: data,
        busy: false,
        clearReview: clearReview,
        notice: notice,
        clearNotice: notice == null,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
