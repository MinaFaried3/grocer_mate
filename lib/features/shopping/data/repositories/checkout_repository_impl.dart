import 'package:grocer_mate/core/network/connectivity/offline_exception.dart';

import '../../domain/entities/shopping.dart';
import '../../domain/repositories/checkout_repository.dart';
import '../models/purchase_request.dart';
import '../sources/checkout_remote_source.dart';

class const CheckoutRepositoryImpl(
  final CheckoutRemoteSource _source,
  final bool Function() _isOnline,
) implements CheckoutRepository {
  @override
  Future<PurchaseResult> purchase(PendingPurchase purchase) async {
    if (!_isOnline()) throw const OfflineException();
    final response = await _source.purchase(
      PurchaseRequest.fromPurchase(purchase),
      idempotencyKey: purchase.id,
    );
    return response.toResult(purchase);
  }
}
