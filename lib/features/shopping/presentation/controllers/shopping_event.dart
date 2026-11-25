import 'package:grocer_mate/features/catalog/domain/catalog.dart';

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
