import 'package:grocer_mate/features/catalog/domain/catalog.dart';

sealed class const ShopEvent();

class const ShopStarted() extends ShopEvent;

class const ItemAdded(final Product product) extends ShopEvent;

class const QuantityAdjusted(final String id, final int delta)
    extends ShopEvent;

class const ItemsMoved(final Set<String> ids, {required final bool fromSaved})
    extends ShopEvent;

class const ItemsRemoved(final Set<String> ids, {required final bool fromSaved})
    extends ShopEvent;

class const CheckoutRequested() extends ShopEvent;

class const PendingRetried() extends ShopEvent;

class const PendingCanceled() extends ShopEvent;

class const CheckoutAccepted(final Map<String, int> quantities)
    extends ShopEvent;
