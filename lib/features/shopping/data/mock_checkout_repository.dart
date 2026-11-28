import 'package:grocer_mate/core/mock/mock_market.dart';
import 'package:grocer_mate/core/network/connectivity/offline_exception.dart';

import '../domain/entities/shopping.dart';
import '../domain/repositories/checkout_repository.dart';
import 'checkout_models.dart';

class const MockCheckoutRepository(
  final MockMarket _market,
  final bool Function() _isOnline,
) implements CheckoutRepository {
  @override
  Future<PurchaseResult> purchase(PendingPurchase purchase) async {
    if (!_isOnline()) throw const OfflineException();
    final result = await _market.purchase(
      PurchaseRequest.fromPurchase(purchase).toJson(),
      key: purchase.id,
    );
    return PurchaseResponse.fromJson(result).toResult(purchase);
  }
}
