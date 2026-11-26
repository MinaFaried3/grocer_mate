import '../entities/shopping.dart';

abstract interface class CheckoutRepository {
  Future<PurchaseResult> purchase(PendingPurchase purchase);
}
